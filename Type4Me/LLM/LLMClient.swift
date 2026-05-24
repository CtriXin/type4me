import Foundation

/// Common interface for LLM clients (OpenAI-compatible and Claude).
protocol LLMClient: Sendable {
    func process(text: String, prompt: String, config: LLMConfig, onToken: (@Sendable (String) -> Void)?) async throws -> String
    func warmUp(baseURL: String) async
}

extension LLMClient {
    func process(text: String, prompt: String, config: LLMConfig) async throws -> String {
        try await process(text: text, prompt: prompt, config: config, onToken: nil)
    }
}

extension String {
    /// Remove `<think>...</think>` reasoning blocks emitted by models like DeepSeek.
    /// Handles both closed tags and unclosed/truncated tags.
    func strippingThinkTags() -> String {
        self
            .replacingOccurrences(of: "<think>[\\s\\S]*?</think>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<think>[\\s\\S]*$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
