import Foundation
import Observation

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    let content: String
    let timestamp: Date
}

@Observable
final class AIChatViewModel {
    var messages: [ChatMessage] = []
    var inputText = ""
    var isLoading = false
    var errorMessage: String?

    func sendMessage(apiClient: APIClient, userId: Int) async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMessage = ChatMessage(role: "user", content: text, timestamp: Date())
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        errorMessage = nil

        do {
            let request = AIChatRequest(userId: userId, message: text)
            let response: AIChatResponse = try await apiClient.sendChatMessage(request: request)

            let assistantMessage = ChatMessage(
                role: "assistant", content: response.reply, timestamp: Date()
            )
            messages.append(assistantMessage)
        } catch {
            errorMessage = "Failed to get AI response. Check server connection."
        }

        isLoading = false
    }
}
