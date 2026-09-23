import Foundation

struct GiraUser: Codable {
    var nome: String = ""
    var email: String = ""
    var perfil: String = ""
    var apelido: String = ""
}

struct GiraSummary: Codable {
    var total: Int = 0
    var minhas: Int = 0
    var concluidas: Int = 0
    var atrasadas: Int = 0
    var proximas: Int = 0
    var emAndamento: Int = 0
    var emRevisao: Int = 0
    var alunosAtivos: Int = 0
}

struct GiraActivity: Codable, Identifiable {
    var id: String = ""
    var atividade: String = ""
    var projeto: String = ""
    var secao: String = ""
    var responsavel: String = ""
    var colaboradores: String = ""
    var inicio: String = ""
    var inicioFmt: String = ""
    var prazo: String = ""
    var prazoFmt: String = ""
    var status: String = "Não iniciada"
    var prioridade: String = ""
    var progresso: Int = 0
    var aprovacao: String = ""
    var observacoes: String = ""
    var link: String = ""
    var diasRestantes: Int? = nil
    var situacaoPrazo: String = ""
    var revision: String = ""
    var canUpdate: Bool = false
    var accessMode: String = "read"
}

struct TeamMember: Codable, Identifiable {
    var nome: String = ""
    var nomeUso: String = ""
    var email: String = ""
    var perfil: String = ""
    var total: Int = 0
    var atrasadas: Int = 0
    var emRevisao: Int = 0
    var emAndamento: Int = 0
    var progressoMedio: Int = 0
    var concluidas: Int = 0
    var tempoMedioConclusaoDias: Double? = nil

    var id: String { email.isEmpty ? nome : email }
}

struct GiraRequest: Codable, Identifiable {
    var requestKey: String = ""
    var revision: String = ""
    var solicitacao: String = ""
    var descricao: String = ""
    var responsavel: String = ""
    var prioridade: String = ""
    var triagem: String = ""

    var id: String { requestKey.isEmpty ? UUID().uuidString : requestKey }
}

struct GiraSnapshot: Codable {
    var version: String = ""
    var portalMode: String = ""
    var user: GiraUser = GiraUser()
    var summary: GiraSummary = GiraSummary()
    var activities: [GiraActivity] = []
    var team: [TeamMember] = []
    var requests: [GiraRequest] = []

    var isOrientador: Bool {
        portalMode.lowercased() == "orientador" ||
        user.perfil.lowercased().contains("orient")
    }
}

struct MobileEnvelope: Encodable {
    let mobileRequest: MobileRequest
}

struct MobileRequest: Encodable {
    let v: Int
    let action: String
    let payload: AnyCodable
    let idToken: String
    let requestId: String
    let client: ClientInfo
}

struct ClientInfo: Encodable {
    let appVersion: String
    let platform: String
    let device: String
}

struct BackendResponse<T: Decodable>: Decodable {
    let ok: Bool
    let data: T?
    let error: String?
    let version: String?
}

struct AnyCodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        encodeClosure = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
