import SwiftUI

struct RootView: View {
    @EnvironmentObject var config: AppConfig
    @EnvironmentObject var auth: GoogleAuthManager
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if !auth.isSignedIn {
                LoginView()
            } else if let snapshot = appState.snapshot {
                MainTabView(snapshot: snapshot)
            } else {
                LoadingView()
            }
        }
        .task {
            guard config.isComplete else {
                appState.errorMessage =
                    "Configuração interna do GIRA inválida."
                return
            }

            if !auth.isSignedIn {
                await auth.restore()

                if auth.isSignedIn {
                    await appState.connect()
                }
            }
        }
    }
}

struct LoginView: View
 {
    @EnvironmentObject var auth: GoogleAuthManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var config: AppConfig
    @State private var signingIn = false
    @State private var localError: String?

    var body: some View {
        ZStack {
            GiraBackground()
            VStack(spacing: 22) {
                GiraBrandHeader()
                Spacer()

                VStack(spacing: 18) {
                    GiraLogo()
                        .frame(width: 86, height: 86)

                    Text("Bem-vindo ao GIRA")
                        .font(.title.bold())

                    Text("Gestão Integrada de Rotinas Acadêmicas")
                        .foregroundStyle(.secondary)

                    Button {
                        Task {
                            signingIn = true
                            defer { signingIn = false }
                            do {
                                try await auth.signIn()
                                await appState.connect()
                            } catch {
                                localError = error.localizedDescription
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                            Text(signingIn ? "Entrando..." : "Entrar com Google")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(signingIn)

                    if let localError {
                        Text(localError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(22)
                .background(
                    .background,
                    in: RoundedRectangle(cornerRadius: 24)
                )
                .shadow(radius: 8, y: 4)
                .padding()

                Spacer()
            }
        }
    }
}

struct LoadingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var auth: GoogleAuthManager

    var body: some View {
        VStack(spacing: 16) {
            GiraLogo()
                .frame(width: 80, height: 80)

            if appState.loading {
                ProgressView()
                Text("Carregando seu GIRA…")
                    .font(.headline)
            } else {
                Text(appState.errorMessage ?? "Não foi possível carregar.")
                    .multilineTextAlignment(.center)
                Button("Tentar novamente") {
                    Task { await appState.loadInitial() }
                }
                Button("Sair") {
                    auth.signOut()
                    appState.clear()
                }
            }
        }
        .padding()
    }
}

struct MainTabView: View {
    let snapshot: GiraSnapshot

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView(snapshot: snapshot)
            }
            .tabItem {
                Label("Início", systemImage: "house.fill")
            }

            NavigationStack {
                ActivitiesView(snapshot: snapshot)
            }
            .tabItem {
                Label("Atividades", systemImage: "checklist")
            }

            if snapshot.isOrientador {
                NavigationStack {
                    TeamView(team: snapshot.team)
                }
                .tabItem {
                    Label("Equipe", systemImage: "person.3.fill")
                }
            } else {
                NavigationStack {
                    RequestsView(requests: snapshot.requests)
                }
                .tabItem {
                    Label("Solicitações", systemImage: "doc.text.fill")
                }
            }

            NavigationStack {
                ProfileView(snapshot: snapshot)
            }
            .tabItem {
                Label("Perfil", systemImage: "person.crop.circle")
            }
        }
        .tint(Color.giraBlue)
    }
}

struct DashboardView: View {
    let snapshot: GiraSnapshot

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HeroCard(snapshot: snapshot)
                SummaryGrid(summary: snapshot.summary)

                HStack {
                    VStack(alignment: .leading) {
                        Text("Prioridades agora")
                            .font(.title3.bold())
                        Text("Prazos mais próximos")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    Spacer()
                }

                ForEach(
                    snapshot.activities.sorted {
                        ($0.diasRestantes ?? 9999) <
                        ($1.diasRestantes ?? 9999)
                    }.prefix(6)
                ) { activity in
                    NavigationLink {
                        ActivityDetailView(activity: activity)
                    } label: {
                        ActivityCard(activity: activity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .refreshable {
            // Root snapshot is refreshed through AppState.
        }
        .navigationTitle("GIRA")
    }
}

struct ActivitiesView: View {
    let snapshot: GiraSnapshot
    @State private var query = ""
    @State private var onlyMine = false

    var filtered: [GiraActivity] {
        snapshot.activities.filter { activity in
            (!onlyMine || activity.canUpdate) &&
            (
                query.isEmpty ||
                activity.atividade.localizedCaseInsensitiveContains(query) ||
                activity.projeto.localizedCaseInsensitiveContains(query) ||
                activity.responsavel.localizedCaseInsensitiveContains(query)
            )
        }
    }

    var body: some View {
        List {
            Toggle("Somente vinculadas a mim", isOn: $onlyMine)

            ForEach(filtered) { activity in
                NavigationLink {
                    ActivityDetailView(activity: activity)
                } label: {
                    ActivityCard(activity: activity)
                }
            }
        }
        .searchable(text: $query, prompt: "Buscar atividade")
        .navigationTitle("Atividades")
    }
}

struct ActivityDetailView: View {
    @EnvironmentObject var appState: AppState
    let activity: GiraActivity
    @State private var progress: Double

    init(activity: GiraActivity) {
        self.activity = activity
        _progress = State(initialValue: Double(activity.progresso))
    }

    var body: some View {
        Form {
            Section("Atividade") {
                Text(activity.atividade)
                    .font(.headline)
                Text(activity.projeto)
                Text("Responsável: \(activity.responsavel)")
                if !activity.prazoFmt.isEmpty {
                    Text("Prazo: \(activity.prazoFmt)")
                }
            }

            Section("Status") {
                HStack {
                    StatusCapsule(text: activity.status)
                    Spacer()
                    Text("\(activity.progresso)%")
                }
            }

            if activity.canUpdate && activity.status != "Em revisão" {
                Section("Progresso") {
                    Slider(value: $progress, in: 0...100, step: 5)
                    Text("\(Int(progress))%")

                    Button("Salvar progresso") {
                        Task {
                            await appState.updateProgress(
                                activity,
                                progress: Int(progress)
                            )
                        }
                    }

                    Button("Concluir / enviar para revisão") {
                        Task {
                            await appState.complete(activity)
                        }
                    }
                }
            }

            if !activity.observacoes.isEmpty {
                Section("Observações") {
                    Text(activity.observacoes)
                }
            }
        }
        .navigationTitle("Atividade")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TeamView: View {
    let team: [TeamMember]

    var body: some View {
        List(team) { person in
            VStack(alignment: .leading, spacing: 4) {
                Text(person.nomeUso.isEmpty ? person.nome : person.nomeUso)
                    .font(.headline)
                Text(
                    "\(person.total) ativas • " +
                    "\(person.concluidas) concluídas • " +
                    "\(person.atrasadas) atrasos"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Equipe em foco")
    }
}

struct RequestsView: View {
    let requests: [GiraRequest]

    var body: some View {
        List(requests) { request in
            VStack(alignment: .leading, spacing: 4) {
                Text(request.solicitacao)
                    .font(.headline)
                if !request.descricao.isEmpty {
                    Text(request.descricao)
                        .font(.caption)
                }
                StatusCapsule(
                    text: request.triagem.isEmpty ? "Novo" : request.triagem
                )
            }
        }
        .navigationTitle("Solicitações")
    }
}

struct ProfileView: View {
    @EnvironmentObject var auth: GoogleAuthManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var config: AppConfig
    let snapshot: GiraSnapshot

    var body: some View {
        Form {
            Section("Usuário") {
                Text(snapshot.user.nome)
                Text(snapshot.user.email)
                Text(snapshot.user.perfil)
            }

            Section("Aplicativo") {
                Text("GIRA iOS 1.0 • Preparação")
                Text("Core \(snapshot.version)")
            }

            Section {
                Button("Sair da Conta Google", role: .destructive) {
                    auth.signOut()
                    appState.clear()
                }
            }
        }
        .navigationTitle("Perfil")
    }
}

struct HeroCard: View {
    let snapshot: GiraSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StatusCapsule(
                text: snapshot.user.perfil.uppercased(),
                inverted: true
            )

            Text(
                "Olá, " +
                (snapshot.user.apelido.isEmpty
                    ? snapshot.user.nome.components(
                        separatedBy: " "
                    ).first ?? snapshot.user.nome
                    : snapshot.user.apelido)
            )
            .font(.title.bold())
            .foregroundStyle(.white)

            Text(
                snapshot.isOrientador
                ? "Acompanhe a equipe, revisões e prazos acadêmicos."
                : "Organize suas atividades e acompanhe seus próximos passos."
            )
            .foregroundStyle(.white.opacity(0.82))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            LinearGradient(
                colors: [.giraNavy, .giraBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24)
        )
    }
}

struct SummaryGrid: View {
    let summary: GiraSummary

    var body: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                MetricCard(
                    title: "Ativas",
                    value: summary.total,
                    symbol: "checklist",
                    color: .giraBlue
                )
                MetricCard(
                    title: "Atrasadas",
                    value: summary.atrasadas,
                    symbol: "exclamationmark.triangle.fill",
                    color: .red
                )
            }
            GridRow {
                MetricCard(
                    title: "Em revisão",
                    value: summary.emRevisao,
                    symbol: "doc.text.magnifyingglass",
                    color: .orange
                )
                MetricCard(
                    title: "Concluídas",
                    value: summary.concluidas,
                    symbol: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: Int
    let symbol: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(color)
            Text("\(value)")
                .font(.title.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            .background,
            in: RoundedRectangle(cornerRadius: 18)
        )
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

struct ActivityCard: View {
    let activity: GiraActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    if !activity.projeto.isEmpty {
                        Text(activity.projeto.uppercased())
                            .font(.caption2.bold())
                            .foregroundStyle(Color.giraBlue)
                    }
                    Text(activity.atividade)
                        .font(.headline)
                }
                Spacer()
                Text(activity.canUpdate ? "Vinculada" : "Leitura")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (activity.canUpdate
                            ? Color.green
                            : Color.giraBlue
                        ).opacity(0.12),
                        in: Capsule()
                    )
            }

            ProgressView(value: Double(activity.progresso), total: 100)

            HStack {
                StatusCapsule(text: activity.status)
                Spacer()
                Text("\(activity.progresso)%")
                    .font(.caption.bold())
            }
        }
        .padding(.vertical, 5)
    }
}

struct StatusCapsule: View {
    let text: String
    var inverted = false

    var body: some View {
        Text(text.isEmpty ? "Não iniciada" : text)
            .font(.caption2.bold())
            .foregroundStyle(inverted ? .white : Color.giraBlue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                inverted
                ? Color.white.opacity(0.16)
                : Color.giraBlue.opacity(0.12),
                in: Capsule()
            )
    }
}

struct GiraBrandHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            GiraLogo()
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text("GIRA")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Gestão Integrada de Rotinas Acadêmicas")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.74))
                Text("● GIPAC • AMBIENTE ACADÊMICO")
                    .font(.caption2.bold())
                    .foregroundStyle(.white.opacity(0.88))
            }
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.giraNavy, .giraBlue],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

struct GiraLogo: View {
    var body: some View {
        Group {
            if let url = Bundle.main.url(
                forResource: "gira_logo",
                withExtension: "png"
            ),
            let data = try? Data(contentsOf: url),
            let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "graduationcap.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.giraBlue)
            }
        }
        .padding(4)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct GiraBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(uiColor: .systemBackground),
                Color.giraBlue.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

extension Color {
    static let giraBlue = Color(
        red: 23 / 255,
        green: 78 / 255,
        blue: 166 / 255
    )

    static let giraNavy = Color(
        red: 6 / 255,
        green: 43 / 255,
        blue: 78 / 255
    )
}
