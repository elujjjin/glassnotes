import Foundation

/// Sends notes to a Telegram chat via the Bot API.
///
/// Notes are escaped and sent as HTML rather than legacy Markdown, because the
/// legacy parser rejects any note containing an unbalanced bracket and silently
/// fails the whole request. Long notes are split across messages, since the API
/// hard-caps a message at 4096 characters.
@MainActor
public final class TelegramSyncService: ObservableObject {
    @Published public private(set) var isSyncing: Bool = false
    @Published public private(set) var statusMessage: String? = nil

    /// Maximum characters Telegram accepts in a single message.
    private static let messageLimit = 4096

    public init() {}

    /// Returns the `message_id` of the first sent message, or `nil` on failure.
    @discardableResult
    public func sendNoteToTelegram(
        botToken: String,
        chatId: String,
        noteTitle: String,
        noteContent: String
    ) async -> Int64? {
        let token = botToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let chat = chatId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !token.isEmpty, !chat.isEmpty else {
            statusMessage = "Telegram bot token and chat ID are required."
            return nil
        }

        guard let url = Self.endpointURL(token: token) else {
            statusMessage = "The bot token is not valid."
            return nil
        }

        let heading = noteTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = noteContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !heading.isEmpty || !body.isEmpty else {
            statusMessage = "This note is empty."
            return nil
        }

        isSyncing = true
        defer { isSyncing = false }

        let formatted = """
        <b>\(Self.escapeHTML(heading.isEmpty ? "Quick note" : heading))</b>

        \(Self.escapeHTML(body))
        """

        let chunks = Self.split(formatted, limit: Self.messageLimit)
        var firstMessageId: Int64?

        for (index, chunk) in chunks.enumerated() {
            switch await Self.post(text: chunk, to: url, chatId: chat) {
            case .success(let messageId):
                if firstMessageId == nil { firstMessageId = messageId }
            case .failure(let message):
                statusMessage = chunks.count > 1
                    ? "Sent \(index) of \(chunks.count) parts, then failed: \(message)"
                    : "Telegram sync failed: \(message)"
                return firstMessageId
            }
        }

        statusMessage = chunks.count > 1
            ? "Sent note to Telegram in \(chunks.count) parts."
            : "Successfully sent note to Telegram."
        return firstMessageId
    }

    // MARK: - Transport

    private static func endpointURL(token: String) -> URL? {
        var components = URLComponents(string: "https://api.telegram.org")
        components?.path = "/bot\(token)/sendMessage"
        return components?.url
    }

    private enum PostResult {
        case success(messageId: Int64?)
        case failure(String)
    }

    private static func post(text: String, to url: URL, chatId: String) async -> PostResult {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "chat_id": chatId,
            "text": text,
            "parse_mode": "HTML",
            "disable_web_page_preview": true,
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                return .failure("No response from Telegram.")
            }

            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let description = json?["description"] as? String

            guard (200..<300).contains(http.statusCode) else {
                return .failure(description ?? "Telegram returned HTTP \(http.statusCode).")
            }

            let result = json?["result"] as? [String: Any]
            let messageId = (result?["message_id"] as? NSNumber)?.int64Value
            return .success(messageId: messageId)
        } catch is DecodingError {
            return .failure("Telegram sent an unreadable response.")
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                return .failure("You appear to be offline.")
            case .timedOut:
                return .failure("Telegram timed out.")
            default:
                return .failure(error.localizedDescription)
            }
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    // MARK: - Formatting helpers

    /// Escapes the three characters Telegram's HTML parser treats as markup.
    /// The ampersand must be replaced first or it double-escapes its own output.
    static func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    /// Splits `text` into chunks of at most `limit` characters, preferring to
    /// break on a newline so the parts stay readable.
    ///
    /// The split is lossless: joining the result reproduces the input exactly,
    /// including every newline. This matters because notes are forwarded
    /// verbatim and silently dropped characters would be unrecoverable.
    static func split(_ text: String, limit: Int) -> [String] {
        guard limit > 0, text.count > limit else { return [text] }

        let units = Array(text)
        var chunks: [String] = []
        var index = units.startIndex

        while units.distance(from: index, to: units.endIndex) > limit {
            let windowEnd = units.index(index, offsetBy: limit)
            var cutEnd = windowEnd

            // Prefer to break immediately after a newline inside the window.
            var scan = windowEnd
            while scan > index {
                scan = units.index(before: scan)
                if units[scan] == "\n" {
                    cutEnd = units.index(after: scan)
                    break
                }
            }

            chunks.append(String(units[index..<cutEnd]))
            index = cutEnd
        }

        let tail = String(units[index...])
        if !tail.isEmpty { chunks.append(tail) }
        return chunks.isEmpty ? [text] : chunks
    }
}
