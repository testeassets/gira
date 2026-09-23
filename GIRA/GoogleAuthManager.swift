import Foundation
import GoogleSignIn
import UIKit

@MainActor
final class GoogleAuthManager: ObservableObject {
    @Published private(set) var idToken: String = ""
    @Published private(set) var email: String = ""
    @Published private(set) var displayName: String = ""

    var isSignedIn: Bool { !idToken.isEmpty }

    func restore() async {
        do {
            let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            apply(user: user)
        } catch {
            idToken = ""
        }
    }

    func signIn() async throws {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController
        else {
            throw AuthError.noPresenter
        }

        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: root
        )
        apply(user: result.user)
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        idToken = ""
        email = ""
        displayName = ""
    }

    private func apply(user: GIDGoogleUser) {
        idToken = user.idToken?.tokenString ?? ""
        email = user.profile?.email ?? ""
        displayName = user.profile?.name ?? ""
    }

    enum AuthError: LocalizedError {
        case noPresenter

        var errorDescription: String? {
            "Não foi possível abrir o login Google."
        }
    }
}
