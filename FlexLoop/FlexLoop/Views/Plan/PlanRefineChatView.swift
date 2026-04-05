import SwiftUI

struct PlanRefineChatView: View {
    let planId: Int
    let userId: Int
    let onApplyChanges: ([APIPlanChange]) -> Void
    @State private var viewModel = PlanRefinerViewModel()
    @State private var inputText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.chatHistory.indices, id: \.self) { index in
                                let msg = viewModel.chatHistory[index]
                                if msg["role"] == "user" {
                                    ChatBubbleView(text: msg["content"] ?? "", isUser: true)
                                        .id("msg-\(index)")
                                } else if msg["role"] == "assistant" {
                                    ChatBubbleView(text: msg["content"] ?? "", isUser: false)
                                        .id("msg-\(index)")
                                }
                            }

                            // Pending changes card
                            if !viewModel.refineChanges.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(String(localized: "refine.chat.proposedChanges"))
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)

                                    ForEach(viewModel.refineChanges) { change in
                                        PlanChangeDiffCard(change: change)
                                    }

                                    HStack(spacing: 12) {
                                        Button {
                                            onApplyChanges(viewModel.refineChanges)
                                            viewModel.clearRefine()
                                        } label: {
                                            Label(String(localized: "refine.chat.apply"), systemImage: "checkmark")
                                                .font(.subheadline.bold())
                                                .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.borderedProminent)

                                        Button {
                                            viewModel.clearRefine()
                                        } label: {
                                            Text(String(localized: "refine.chat.reject"))
                                                .font(.subheadline)
                                                .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                                .padding(12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .id("changes")
                            }

                            // Loading indicator
                            if viewModel.isLoadingRefine {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text(String(localized: "refine.chat.thinking"))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .id("loading")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.chatHistory.count) {
                        withAnimation {
                            proxy.scrollTo("msg-\(viewModel.chatHistory.count - 1)", anchor: .bottom)
                        }
                    }
                    .onChange(of: viewModel.refineChanges.count) {
                        withAnimation {
                            proxy.scrollTo("changes", anchor: .bottom)
                        }
                    }
                }

                // Error
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Divider()

                // Input
                HStack(spacing: 8) {
                    TextField(String(localized: "refine.chat.placeholder"), text: $inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)

                    Button {
                        let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !message.isEmpty else { return }
                        inputText = ""
                        let apiClient = APIClient(config: .current)
                        Task {
                            await viewModel.refinePlan(
                                apiClient: apiClient, planId: planId,
                                userId: userId, message: message
                            )
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoadingRefine)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .navigationTitle(String(localized: "refine.chat.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) { dismiss() }
                }
            }
        }
    }
}

private struct ChatBubbleView: View {
    let text: String
    let isUser: Bool

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            Text(text)
                .padding(12)
                .background(isUser ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            if !isUser { Spacer(minLength: 60) }
        }
    }
}
