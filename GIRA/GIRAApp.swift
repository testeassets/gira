import SwiftUI
import GoogleSignIn

@main
struct GIRAApp: App {
    @StateObject private var config = AppConfig()
    @StateObject private var auth = GoogleAuthManager()
    @StateObject private var appState: AppState

    init() {
        let config = AppConfig()
        let auth = GoogleAuthManager()
        _config = StateObject(wrappedValue: config)
        _auth = StateObject(wrappedValue: auth)
        _appState = StateObject(
            wrappedValue: AppState(config: config, auth: auth)
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(config)
                .environmentObject(auth)
                .environmentObject(appState)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
