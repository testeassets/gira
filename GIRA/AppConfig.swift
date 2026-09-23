import Foundation

@MainActor
final class AppConfig: ObservableObject {
    let backendURL: String
    let serverClientID: String

    init() {
        backendURL =
            Bundle.main.object(forInfoDictionaryKey: "GIRABackendURL") as? String
            ?? ""

        serverClientID =
            Bundle.main.object(forInfoDictionaryKey: "GIDServerClientID") as? String
            ?? ""
    }

    var isComplete: Bool {
        backendURL.hasPrefix("https://script.google.com/macros/s/") &&
        backendURL.hasSuffix("/exec") &&
        serverClientID.hasSuffix(".apps.googleusercontent.com")
    }
}
