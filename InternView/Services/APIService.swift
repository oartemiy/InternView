import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(String)
    case httpError(Int)
    case unauthorized
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Неверный URL"
        case .noData: return "Нет данных"
        case .decodingError(let msg): return "Ошибка обработки данных: \(msg)"
        case .httpError(let code): return "Ошибка сервера: \(code)"
        case .unauthorized: return "Неверный логин или пароль"
        case .unknown(let msg): return "Неизвестная ошибка: \(msg)"
        }
    }
}

class APIService {
    static let shared = APIService()
    private init() {}

    private var authHeader: String?

    func setAuth(login: String, password: String) {
        let data = "\(login):\(password)".data(using: .utf8)!
        authHeader = "Basic \(data.base64EncodedString())"
    }

    func clearAuth() {
        authHeader = nil
    }

    // MARK: - JSON Request
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: Constants.baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let authHeader = authHeader {
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                print("❌ Body encoding error: \(error)")
                throw APIError.unknown("Body encoding error: \(error.localizedDescription)")
            }
        }

        print("➡️ Request: \(method) \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown("Invalid response")
        }

        print("⬅️ Response status: \(httpResponse.statusCode)")
        if let str = String(data: data, encoding: .utf8) {
            print("⬅️ Response data: \(str)")
        }

        // Отладка: посмотрим, что в JSON словаре
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("🔍 JSON dictionary: \(json)")
        }

        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
//            decoder.keyDecodingStrategy = .convertFromSnakeCase

            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            decoder.dateDecodingStrategy = .formatted(dateFormatter)

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("❌ Decoding error: \(error)")
                throw APIError.decodingError(error.localizedDescription)
            }

        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.httpError(httpResponse.statusCode)
        }
    }

    // MARK: - Multipart Request (для загрузки файлов)
    func uploadMultipart<T: Decodable>(
        endpoint: String,
        method: String = "POST",
        parameters: [String: String],
        fileData: Data?,
        fileKey: String,
        fileName: String,
        mimeType: String
    ) async throws -> T {
        guard let url = URL(string: Constants.baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let authHeader = authHeader {
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }

        var body = Data()

        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        if let fileData = fileData {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(fileKey)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        print("➡️ Multipart request: \(method) \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown("Invalid response")
        }

        print("⬅️ Response status: \(httpResponse.statusCode)")
        if let str = String(data: data, encoding: .utf8) {
            print("⬅️ Response data: \(str)")
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("🔍 JSON dictionary: \(json)")
        }

        switch httpResponse.statusCode {
        case 200...299:
            if T.self == EmptyResponse.self && data.isEmpty {
                    return EmptyResponse() as! T
                }

            let decoder = JSONDecoder()
//            decoder.keyDecodingStrategy = .convertFromSnakeCase

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            decoder.dateDecodingStrategy = .formatted(dateFormatter)

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("❌ Decoding error: \(error)")
                throw APIError.decodingError(error.localizedDescription)
            }
        case 401:
            throw APIError.unauthorized
        default:
            throw APIError.httpError(httpResponse.statusCode)
        }
    }
}
