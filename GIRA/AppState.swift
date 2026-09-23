import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var snapshot: GiraSnapshot?
    @Published var loading = false
    @Published var errorMessage: String?

    private let config: AppConfig
    private let auth: GoogleAuthManager
    private var api: GiraAPI?

    init(config: AppConfig, auth: GoogleAuthManager) {
        self.config = config
        self.auth = auth
    }

    func connect() async {
        api = GiraAPI(config: config, auth: auth)
        await loadInitial()
    }

    func loadInitial() async {
        guard let api else { return }
        loading = true
        errorMessage = nil
        defer { loading = false }

        do {
            snapshot = try await api.initSnapshot()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        guard let api else { return }
        loading = true
        errorMessage = nil
        defer { loading = false }

        do {
            snapshot = try await api.refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateProgress(_ activity: GiraActivity, progress: Int) async {
        guard let api else { return }
        do {
            snapshot = try await api.updateProgress(
                activity: activity,
                progress: progress
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func complete(_ activity: GiraActivity) async {
        guard let api else { return }
        do {
            snapshot = try await api.complete(activity: activity)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func approve(_ activity: GiraActivity) async {
        guard let api else { return }
        do {
            snapshot = try await api.approve(activity: activity)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clear() {
        snapshot = nil
        api = nil
        errorMessage = nil
    }
}
