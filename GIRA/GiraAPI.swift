import Foundation
import UIKit

actor GiraAPI {
    private let config: AppConfig
    private let auth: GoogleAuthManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(config: AppConfig, auth: GoogleAuthManager) {
        self.config = config
        self.auth = auth
    }

    func initSnapshot() async throws -> GiraSnapshot {
        try await call(action: "init", payload: [String: String]())
    }

    func refresh() async throws -> GiraSnapshot {
        try await call(action: "refresh", payload: [String: String]())
    }

    func updateProgress(
        activity: GiraActivity,
        progress: Int
    ) async throws -> GiraSnapshot {
        try await call(
            action: "updateProgress",
            payload: [
                "id": activity.id,
                "progress": String(progress),
                "revision": activity.revision
            ]
        )
    }

    func complete(activity: GiraActivity) async throws -> GiraSnapshot {
        try await call(
            action: "complete",
            payload: [
                "id": activity.id,
                "revision": activity.revision
            ]
        )
    }

    func approve(activity: GiraActivity) async throws -> GiraSnapshot {
        try await call(
            action: "approve",
            payload: [
                "id": activity.id,
                "revision": activity.revision
            ]
        )
    }

    private func call<T: Decodable, P: Encodable>(
        action: String,
        payload: P
    ) async throws -> T {
        let backend = await MainActor.run { config.backendURL }
        let token = await MainActor.run { auth.idToken }

        guard let url = URL(string: backend) else {
            throw APIError.invalidBackend
        }
        guard !token.isEmpty else {
            throw APIError.notAuthenticated
        }

        let requestId =
            UUID().uuidString.replacingOccurrences(of: "-", with: "") +
            UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8)

        let appVersion =
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "1.0.0"

        let mobile = MobileRequest(
            v: 1,
            action: action,
            payload: AnyCodable(payload),
            idToken: token,
            requestId: requestId,
            client: ClientInfo(
                appVersion: appVersion,
                platform: "iOS \(UIDevice.current.systemVersion)",
                device: UIDevice.current.model
            )
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json; charset=utf-8",
            forHTTPHeaderField: "Content-Type"
        )
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(
            MobileEnvelope(mobileRequest: mobile)
        )
        request.timeoutInterval = 90

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw APIError.http(http.statusCode)
        }

        let root = try decoder.decode(
            BackendResponse<T>.self,
            from: data
        )

        guard root.ok, let result = root.data else {
            throw APIError.backend(
                root.error ?? "Falha desconhecida no Backend."
            )
        }

        return result
    }

    enum APIError: LocalizedError {
        case invalidBackend
        case notAuthenticated
        case invalidResponse
        case http(Int)
        case backend(String)

        var errorDescription: String? {
            switch self {
            case .invalidBackend:
                return "URL do Backend inválida."
            case .notAuthenticated:
                return "Sessão Google ausente."
            case .invalidResponse:
                return "Resposta inválida do Backend."
            case .http(let code):
                return "Falha HTTP \(code)."
            case .backend(let message):
                return message
            }
        }
    }
}
