import SwiftUI

@main
struct KitchenAssistantApp: App {
    init() {
        print("============================================================")
        print("🍳🍳🍳 Kitchen Assistant App 啟動！🍳🍳🍳")
        print("📱 Version: 1.0.0")
        print("⏰ Time: \(Date())")
        print("============================================================")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}