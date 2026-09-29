import Foundation

@MainActor
public final class TelegramSyncService: ObservableObject {
    @Published public var isSyncing: Bool = false
    @Published public var statusMessage: String? = nil

    public func sendNoteToTelegram(botToken: String, chatId: String, noteTitle: String, noteContent: String) async -> Bool {
        guard !botToken.isEmpty, !chatId.isEmpty else {
            self.statusMessage = "Telegram Bot Token and Chat ID required."
            return false
        }
        
        self.isSyncing = true
        defer { self.isSyncing = false }
        
        let text = """
        📝 *\(escapeMarkdown(noteTitle))*
        
        \(noteContent)
        """
        
        let urlString = "https://api.telegram.org/bot\(botToken)/sendMessage"
        guard let url = URL(string: urlString) else {
            self.statusMessage = "Invalid Telegram API URL"
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "chat_id": chatId,
            "text": text,
            "parse_mode": "Markdown"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                self.statusMessage = "Successfully sent note to Telegram!"
                return true
            } else {
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown server error"
                self.statusMessage = "Telegram sync failed: \(errorString)"
                return false
            }
        } catch {
            self.statusMessage = "Network error: \(error.localizedDescription)"
            return false
        }
    }
    
    private func escapeMarkdown(_ text: String) -> String {
        return text.replacingOccurrences(of: "*", with: "\\*")
                   .replacingOccurrences(of: "_", with: "\\_")
                   .replacingOccurrences(of: "`", with: "\\`")
    }
}
