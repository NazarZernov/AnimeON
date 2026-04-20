import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

struct APIRequest {
    let path: String
    let method: HTTPMethod
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: (any Encodable)?
}

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case emptyBody

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Не удалось собрать URL запроса."
        case .invalidResponse:
            return "Сервер вернул неожиданный ответ."
        case let .serverError(statusCode):
            return "Сервер вернул ошибку \(statusCode)."
        case .emptyBody:
            return "Сервер вернул пустое тело ответа."
        }
    }
}

struct EmptyResponse: Decodable {}

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ wrapped: any Encodable) {
        encodeClosure = wrapped.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

final class NetworkClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: URL,
        session: URLSession? = nil,
        decoder: JSONDecoder? = nil,
        encoder: JSONEncoder? = nil
    ) {
        self.baseURL = baseURL

        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.waitsForConnectivity = true
            configuration.timeoutIntervalForRequest = 25
            configuration.timeoutIntervalForResource = 120
            configuration.requestCachePolicy = .returnCacheDataElseLoad
            configuration.urlCache = URLCache(
                memoryCapacity: 64 * 1_024 * 1_024,
                diskCapacity: 256 * 1_024 * 1_024
            )
            self.session = URLSession(configuration: configuration)
        }

        let resolvedDecoder = decoder ?? JSONDecoder()
        resolvedDecoder.dateDecodingStrategy = .iso8601
        self.decoder = resolvedDecoder

        let resolvedEncoder = encoder ?? JSONEncoder()
        resolvedEncoder.dateEncodingStrategy = .iso8601
        self.encoder = resolvedEncoder
    }

    func send<Response: Decodable>(_ request: APIRequest, as type: Response.Type) async throws -> Response {
        let urlRequest = try buildURLRequest(from: request)
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }

        guard !data.isEmpty else {
            if let empty = EmptyResponse() as? Response {
                return empty
            }
            throw NetworkError.emptyBody
        }

        return try decoder.decode(Response.self, from: data)
    }

    func send(_ request: APIRequest) async throws {
        _ = try await send(request, as: EmptyResponse.self)
    }

    private func buildURLRequest(from request: APIRequest) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(request.path), resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }

        if !request.queryItems.isEmpty {
            components.queryItems = request.queryItems
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("AnimeOnNative/2.0", forHTTPHeaderField: "User-Agent")

        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if let body = request.body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try encoder.encode(AnyEncodable(body))
        }

        return urlRequest
    }
}
