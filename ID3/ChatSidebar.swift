import SwiftUI

struct ChatSidebar: View {
    @Binding var messages: [ChatMessage]
    var closeAction: () -> Void

    @State private var draft: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(16)
                }
                .background(Color.ideSidebar)
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            Divider()
            inputArea
                .padding(12)
                .background(Color.ideBackground)
        }
        .frame(maxHeight: .infinity)
    }

    private var header: some View {
        HStack {
            Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            Button(action: closeAction) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.15)))
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var inputArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ChipButton(label: "Analyze")
                ChipButton(label: "Explain")
                ChipButton(label: "Summarize")
            }

            VStack(spacing: 6) {
                TextField("Ask a question about this page…", text: $draft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .focused($isInputFocused)
                    .onSubmit(sendMessage)
                    .frame(minHeight: 28)

                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Button(action: {}) {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(ChatAccessoryButtonStyle())

                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                        }
                        .buttonStyle(ChatAccessoryButtonStyle())
                    }

                    Spacer()

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up")
                    }
                    .buttonStyle(ChatAccessoryButtonStyle(filled: true, tint: Color.gray.opacity(0.35)))
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 3)
            )
        }
    }

    private func sendMessage() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(ChatMessage(role: .user, text: trimmed))
        draft = ""
        isInputFocused = true
    }
}

struct ChatMessage: Identifiable, Hashable {
    enum Role {
        case user, assistant

        var bubbleColor: Color {
            switch self {
            case .user: return Color.ideAccent.opacity(0.15)
            case .assistant: return Color.gray.opacity(0.15)
            }
        }
    }

    let id = UUID()
    let role: Role
    let text: String
}

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .assistant { Spacer(minLength: 0) }
            Text(message.text)
                .font(.system(size: 13))
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(message.role.bubbleColor))
                .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
            if message.role == .user { Spacer(minLength: 0) }
        }
    }
}

private struct ChipButton: View {
    let label: String

    var body: some View {
        Button(action: {}) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.secondary.opacity(0.18)))
        }
        .buttonStyle(.plain)
    }
}

private struct ChatAccessoryButtonStyle: ButtonStyle {
    var filled: Bool = false
    var tint: Color = Color.secondary.opacity(0.15)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .frame(width: 24, height: 24)
            .foregroundColor(filled ? .white : .secondary)
            .background(
                Circle().fill(
                    filled ? tint : tint.opacity(configuration.isPressed ? 0.5 : 1)
                )
            )
    }
}
