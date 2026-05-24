import Foundation

// MARK: - Provider Enum

enum LLMProvider: String, CaseIterable, Codable, Sendable {
    case doubao
    case minimaxCN
    case minimaxIntl
    case bailian
    case kimi
    case openrouter
    case openai
    case gemini
    case deepseek
    case zhipu
    case claude
    case ollama
    case custom

    var displayName: String {
        switch self {
        case .doubao:      return L("豆包 (ByteDance ARK)", "Doubao (ByteDance ARK)")
        case .minimaxCN:   return L("MiniMax 国内", "MiniMax China")
        case .minimaxIntl: return L("MiniMax 海外", "MiniMax Global")
        case .bailian:     return L("百炼 (阿里云)", "Bailian (Alibaba Cloud)")
        case .kimi:        return L("Kimi (月之暗面)", "Kimi (Moonshot)")
        case .openrouter:  return "OpenRouter"
        case .openai:      return "OpenAI"
        case .gemini:      return "Gemini (Google)"
        case .deepseek:    return L("DeepSeek (深度求索)", "DeepSeek")
        case .zhipu:       return L("智谱 (GLM)", "Zhipu (GLM)")
        case .claude:      return "Claude (Anthropic)"
        case .ollama:      return L("Ollama (本地模型)", "Ollama (Local)")
        case .custom:      return L("自定义 (OpenAI 兼容)", "Custom (OpenAI Compatible)")
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .doubao:      return "https://ark.cn-beijing.volces.com/api/v3"
        case .minimaxCN:   return "https://api.minimaxi.com/v1"
        case .minimaxIntl: return "https://api.minimax.io/v1"
        case .bailian:     return "https://dashscope.aliyuncs.com/compatible-mode/v1"
        case .kimi:        return "https://api.moonshot.ai/v1"
        case .openrouter:  return "https://openrouter.ai/api/v1"
        case .openai:      return "https://api.openai.com/v1"
        case .gemini:      return "https://generativelanguage.googleapis.com/v1beta/openai"
        case .deepseek:    return "https://api.deepseek.com"
        case .zhipu:       return "https://open.bigmodel.cn/api/paas/v4"
        case .claude:      return "https://api.anthropic.com/v1"
        case .ollama:      return "http://localhost:11434/v1"
        case .custom:      return ""
        }
    }

    // MARK: - Model Options

    /// Popular models for this provider, shown as dropdown options in settings.
    var modelOptions: [FieldOption] {
        switch self {
        case .doubao:
            return [
                FieldOption(value: "doubao-seed-2-0-mini-260215", label: "doubao-seed-2-0-mini-260215"),
                FieldOption(value: "doubao-seed-2-0-lite-260215", label: "doubao-seed-2-0-lite-260215"),
                FieldOption(value: "doubao-seed-2-0-pro-260215", label: "doubao-seed-2-0-pro-260215"),
                FieldOption(value: "doubao-seed-1-6-flash-250828", label: "doubao-seed-1-6-flash-250828"),
                FieldOption(value: "doubao-1-5-pro-32k-250115", label: "doubao-1-5-pro-32k-250115"),
                FieldOption(value: "doubao-1-5-lite-32k-250115", label: "doubao-1-5-lite-32k-250115"),
            ]
        case .minimaxCN, .minimaxIntl:
            return [
                FieldOption(value: "MiniMax-M2.7", label: "MiniMax-M2.7"),
                FieldOption(value: "MiniMax-M2.7-highspeed", label: "MiniMax-M2.7-highspeed"),
                FieldOption(value: "MiniMax-M2.5", label: "MiniMax-M2.5"),
                FieldOption(value: "MiniMax-M2.5-highspeed", label: "MiniMax-M2.5-highspeed"),
                FieldOption(value: "MiniMax-M2.1", label: "MiniMax-M2.1"),
            ]
        case .bailian:
            return [
                FieldOption(value: "qwen3.6-plus", label: "qwen3.6-plus"),
                FieldOption(value: "qwen3.5-flash", label: "qwen3.5-flash"),
                FieldOption(value: "qwen3-max", label: "qwen3-max"),
                FieldOption(value: "qwen-plus", label: "qwen-plus"),
                FieldOption(value: "qwen-turbo", label: "qwen-turbo"),
                FieldOption(value: "qwen-long", label: "qwen-long"),
            ]
        case .kimi:
            return [
                FieldOption(value: "kimi-k2.5", label: "kimi-k2.5"),
                FieldOption(value: "kimi-k2-turbo-preview", label: "kimi-k2-turbo-preview"),
                FieldOption(value: "moonshot-v1-auto", label: "moonshot-v1-auto"),
                FieldOption(value: "moonshot-v1-128k", label: "moonshot-v1-128k"),
                FieldOption(value: "moonshot-v1-32k", label: "moonshot-v1-32k"),
            ]
        case .openai:
            return [
                FieldOption(value: "gpt-5.4-nano", label: "gpt-5.4-nano"),
                FieldOption(value: "gpt-5.4-mini", label: "gpt-5.4-mini"),
                FieldOption(value: "gpt-5.4", label: "gpt-5.4"),
                FieldOption(value: "gpt-4.1-nano", label: "gpt-4.1-nano"),
                FieldOption(value: "gpt-4.1-mini", label: "gpt-4.1-mini"),
                FieldOption(value: "gpt-4.1", label: "gpt-4.1"),
                FieldOption(value: "gpt-4o-mini", label: "gpt-4o-mini"),
                FieldOption(value: "o4-mini", label: "o4-mini"),
            ]
        case .gemini:
            return [
                FieldOption(value: "gemini-2.5-flash", label: "gemini-2.5-flash"),
                FieldOption(value: "gemini-2.5-pro", label: "gemini-2.5-pro"),
                FieldOption(value: "gemini-2.5-flash-lite", label: "gemini-2.5-flash-lite"),
                FieldOption(value: "gemini-2.0-flash", label: "gemini-2.0-flash"),
                FieldOption(value: "gemini-3.1-pro-preview", label: "gemini-3.1-pro-preview"),
                FieldOption(value: "gemini-3.1-flash-lite-preview", label: "gemini-3.1-flash-lite-preview"),
            ]
        case .deepseek:
            return [
                FieldOption(value: "deepseek-chat", label: "deepseek-chat"),
                FieldOption(value: "deepseek-reasoner", label: "deepseek-reasoner"),
            ]
        case .zhipu:
            return [
                FieldOption(value: "glm-5", label: "glm-5"),
                FieldOption(value: "glm-5-turbo", label: "glm-5-turbo"),
                FieldOption(value: "glm-4.7-flash", label: "glm-4.7-flash"),
                FieldOption(value: "glm-4.5-flash", label: "glm-4.5-flash"),
                FieldOption(value: "glm-4.5-air", label: "glm-4.5-air"),
                FieldOption(value: "glm-4-long", label: "glm-4-long"),
            ]
        case .claude:
            return [
                FieldOption(value: "claude-sonnet-4-6", label: "claude-sonnet-4-6"),
                FieldOption(value: "claude-opus-4-6", label: "claude-opus-4-6"),
                FieldOption(value: "claude-haiku-4-5-20251001", label: "claude-haiku-4-5-20251001"),
                FieldOption(value: "claude-sonnet-4-5-20250929", label: "claude-sonnet-4-5-20250929"),
            ]
        case .openrouter, .ollama, .custom:
            return []
        }
    }

    var isOpenAICompatible: Bool {
        self != .claude
    }

    /// Whether this is a local provider bundled with the app (no external service).
    var isLocal: Bool {
        self == .ollama
    }

    /// Whether this provider requires an API key for authentication.
    var requiresAPIKey: Bool {
        self != .ollama
    }

    /// Thinking/reasoning disable strategy for this provider.
    /// Each provider uses a different field name to turn off chain-of-thought.
    /// Returns nil for providers where no explicit disable is needed or possible.
    var thinkingDisableField: ThinkingDisableField? {
        switch self {
        case .doubao, .kimi, .deepseek:
            // thinking: { type: "disabled" }
            return .thinking
        case .bailian:
            // enable_thinking: false (Qwen models)
            return .enableThinking
        case .zhipu:
            // reasoning_effort: "none" (GLM-4.5+)
            return .reasoningEffort
        case .ollama:
            // think: false
            return .think
        default:
            // OpenAI: defaults to none already for GPT-5.2+, risky for o3
            // Gemini: OpenAI-compat layer doesn't reliably support it
            // MiniMax: API doesn't support disabling reasoning (use needsReasoningSplit instead)
            // OpenRouter: proxy, can't generically handle
            return nil
        }
    }

    /// MiniMax M2+ models always reason and can't be turned off.
    /// reasoning_split=true separates thinking into reasoning_details field,
    /// keeping it out of delta.content so our SSE parser won't pick it up.
    var needsReasoningSplit: Bool {
        self == .minimaxCN || self == .minimaxIntl
    }
}

// MARK: - Thinking Disable Strategy

enum ThinkingDisableField {
    /// `thinking: { type: "disabled" }` — Doubao, Kimi, DeepSeek
    case thinking
    /// `enable_thinking: false` — Bailian (Qwen)
    case enableThinking
    /// `reasoning_effort: "none"` — Zhipu (GLM)
    case reasoningEffort
    /// `think: false` — Ollama
    case think
}

// MARK: - Provider Config Protocol

protocol LLMProviderConfig: Sendable {
    static var provider: LLMProvider { get }
    static var credentialFields: [CredentialField] { get }

    init?(credentials: [String: String])
    func toCredentials() -> [String: String]
    func toLLMConfig() -> LLMConfig
}
