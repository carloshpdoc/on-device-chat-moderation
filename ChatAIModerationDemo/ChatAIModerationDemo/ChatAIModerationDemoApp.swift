
import SwiftUI

@main
struct ChatAIApp: App {
    var body: some Scene {
        WindowGroup {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    ChatView()
                }
            } else {
                NavigationView {
                    ChatView()
                }
            }
        }
    }
}
