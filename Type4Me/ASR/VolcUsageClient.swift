import Foundation
import CryptoKit

/// Queries Volcano Engine OpenAPI for ASR resource usage.
/// Requires IAM credentials (Access Key ID + Secret Access Key) separate from
/// the ASR AppKey/AccessKey used for the WebSocket API.
enum VolcUsageClient {

    struct UsageResult {
        let purchasedHours: Double
        let usedHours: Double
        let expiresAt: String?
    }

    // MARK: - Credential storage (UserDefaults)

    private static let akKey = "tf_volcOpenAPI_AK"
    private static let skKey = "tf_volcOpenAPI_SK"
    private static let region = "cn-north-1"
    private static let service = "cv"

    static var hasCredentials: Bool {
        guard let ak = UserDefaults.standard.string(forKey: akKey), !ak.isEmpty,
              let sk = UserDefaults.standard.string(forKey: skKey), !sk.isEmpty
        else { return false }
        return true
    }

    static func saveCredentials(ak: String, sk: String) {
        UserDefaults.standard.set(ak, forKey: akKey)
        UserDefaults.standard.set(sk, forKey: skKey)
    }

    static func loadCredentials() -> (ak: String, sk: String) {
        (
            UserDefaults.standard.string(forKey: akKey) ?? "",
            UserDefaults.standard.string(forKey: skKey) ?? ""
        )
    }

    // MARK: - API Call

    static func fetchUsage() async throws -> UsageResult {
        let (ak, sk) = loadCredentials()
        guard !ak.isEmpty, !sk.isEmpty else {
            throw VolcUsageError.noCredentials
        }

        let host = "open.volcengineapi.com"
        let action = "UsageMonitoring"
        let version = "2024-11-19"
        let method = "GET"
        let path = "/"

        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let xDate = dateFormatter.string(from: now)

        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyyMMdd"
        dateOnlyFormatter.timeZone = TimeZone(identifier: "UTC")
        let dateStamp = dateOnlyFormatter.string(from: now)

        // Query params for usage monitoring
        let queryParams: [(String, String)] = [
            ("Action", action),
            ("Version", version),
        ]
        let canonicalQueryString = queryParams
            .sorted { $0.0 < $1.0 }
            .map { "\($0.0)=\($0.1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.1)" }
            .joined(separator: "&")

        let payloadHash = SHA256.hash(data: Data()).map { String(format: "%02x", $0) }.joined()
        let signedHeaders = "host;x-date"
        let canonicalHeaders = "host:\(host)\nx-date:\(xDate)\n"

        let canonicalRequest = [
            method, path, canonicalQueryString,
            canonicalHeaders, signedHeaders, payloadHash,
        ].joined(separator: "\n")

        let canonicalRequestHash = SHA256.hash(data: canonicalRequest.data(using: .utf8) ?? Data())
            .map { String(format: "%02x", $0) }.joined()

        let credentialScope = "\(dateStamp)/\(region)/\(service)/request"
        let stringToSign = [
            "HMAC-SHA256", xDate, credentialScope, canonicalRequestHash,
        ].joined(separator: "\n")

        let signingKey = deriveSigningKey(sk: sk, dateStamp: dateStamp)
        let finalSignature = Data(
            HMAC<SHA256>.authenticationCode(
                for: stringToSign.data(using: .utf8)!,
                using: SymmetricKey(data: signingKey)
            )
        ).map { String(format: "%02x", $0) }.joined()

        let authorization = "HMAC-SHA256 Credential=\(ak)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(finalSignature)"

        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        components.queryItems = queryParams.map { URLQueryItem(name: $0.0, value: $0.1) }

        guard let url = components.url else { throw VolcUsageError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        request.setValue(xDate, forHTTPHeaderField: "X-Date")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw VolcUsageError.invalidResponse }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw VolcUsageError.httpError(http.statusCode, body)
        }

        // Parse response - try common response shapes
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw VolcUsageError.parseError("invalid JSON")
        }

        // Volcano API wraps result in "Result" or "data"
        let result = json["Result"] as? [String: Any] ?? json["data"] as? [String: Any] ?? json

        // Try to extract usage from various response shapes
        let purchased = extractDouble(from: result, keys: ["PurchasedHours", "TotalQuota", "Quota", "purchased_hours", "total"])
        let used = extractDouble(from: result, keys: ["UsedHours", "Used", "Consumed", "used_hours", "used"])
        let expires = extractString(from: result, keys: ["ExpiresAt", "Expiration", "expires_at"])

        return UsageResult(
            purchasedHours: purchased,
            usedHours: used,
            expiresAt: expires
        )
    }

    // MARK: - HMAC Helpers

    /// Derive signing key: HMAC-SHA256 chain → SK → date → region → service → "request"
    private static func deriveSigningKey(sk: String, dateStamp: String) -> Data {
        let kDate = Data(HMAC<SHA256>.authenticationCode(
            for: dateStamp.data(using: .utf8)!,
            using: SymmetricKey(data: Data(sk.utf8))
        ))
        let kRegion = Data(HMAC<SHA256>.authenticationCode(
            for: region.data(using: .utf8)!,
            using: SymmetricKey(data: kDate)
        ))
        let kService = Data(HMAC<SHA256>.authenticationCode(
            for: service.data(using: .utf8)!,
            using: SymmetricKey(data: kRegion)
        ))
        return Data(HMAC<SHA256>.authenticationCode(
            for: "request".data(using: .utf8)!,
            using: SymmetricKey(data: kService)
        ))
    }

    private static func extractDouble(from dict: [String: Any], keys: [String]) -> Double {
        for key in keys {
            if let val = dict[key] as? Double { return val }
            if let val = dict[key] as? Int { return Double(val) }
            if let val = dict[key] as? String, let d = Double(val) { return d }
            // Nested: try "Result" → key
            if let nested = dict["Result"] as? [String: Any] {
                if let val = nested[key] as? Double { return val }
                if let val = nested[key] as? Int { return Double(val) }
                if let val = nested[key] as? String, let d = Double(val) { return d }
            }
        }
        return 0
    }

    private static func extractString(from dict: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let val = dict[key] as? String { return val }
            if let nested = dict["Result"] as? [String: Any] {
                if let val = nested[key] as? String { return val }
            }
        }
        return nil
    }
}

enum VolcUsageError: Error, LocalizedError {
    case noCredentials
    case invalidURL
    case invalidResponse
    case httpError(Int, String)
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .noCredentials:
            return "请先配置火山引擎 OpenAPI 凭证 (Access Key ID + Secret Access Key)"
        case .invalidURL:
            return "URL 无效"
        case .invalidResponse:
            return "响应无效"
        case .httpError(let code, let body):
            return "HTTP \(code): \(body.prefix(200))"
        case .parseError(let msg):
            return "解析失败: \(msg)"
        }
    }
}
