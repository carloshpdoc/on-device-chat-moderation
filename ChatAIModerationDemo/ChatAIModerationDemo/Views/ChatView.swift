
import SwiftUI
import ChatAICore

public struct ChatView: View {
    @StateObject private var vm: ChatViewModel

    public init() {
        let policy = ModerationService.loadPolicy()
        // Troque FakeScorer pelo seu scorer real quando tiver o .mlmodel
        let scorer = FakeScorer()
        let moderation = ModerationService(policy: policy, scorer: scorer)
        _vm = StateObject(wrappedValue: ChatViewModel(moderation: moderation))
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(vm.messages) { msg in
                            HStack {
                                if msg.isUser { Spacer() }
                                Text(msg.text)
                                    .padding(12)
                                    .background(msg.isUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                if !msg.isUser { Spacer() }
                            }
                            .id(msg.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: vm.messages.count) { _ in
                    if let last = vm.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }

            if let reason = vm.lastModerationReason {
                Text("Mensagem bloqueada: \(reason)")
                    .font(.footnote)
                    .foregroundStyle(Color.red)
                    .padding(.horizontal)
                    .padding(.top, 6)
            }

            HStack(spacing: 8) {
                TextField("Escreva uma mensagem…", text: $vm.input)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(4)

                Button("Enviar") { vm.send() }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Chat Moderado (Local)")
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        NavigationStack { ChatView() }
    } else {
        NavigationView { ChatView() }
    }
}
