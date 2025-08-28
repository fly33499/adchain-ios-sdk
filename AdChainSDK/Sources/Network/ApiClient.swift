import Foundation

internal class ApiClient {
    private let config: AdChainConfig
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init(config: AdChainConfig) {
        self.config = config
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.apiTimeout
        configuration.httpAdditionalHeaders = [
            "X-AdChain-App-Id": config.appId,
            "X-AdChain-App-Secret": config.appSecret,
            "X-AdChain-SDK-Version": "1.0.0",
            "X-AdChain-Platform": "iOS"
        ]
        
        self.session = URLSession(configuration: configuration)
    }
    
    func validateCredentials(appId: String, appSecret: String, completion: @escaping (Result<ValidateResponse, AdChainError>) -> Void) {
        let endpoint = "/v1/sdk/validate"
        let body = ["app_id": appId, "app_secret": appSecret]
        
        post(endpoint: endpoint, body: body) { (result: Result<ValidateResponse, AdChainError>) in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchCarouselAds(unitId: String, count: Int, completion: @escaping (Result<[CarouselAdResponse], AdChainError>) -> Void) {
        let endpoint = "/v1/carousel/ads"
        let parameters = ["unit_id": unitId, "count": String(count)]
        
        get(endpoint: endpoint, parameters: parameters) { (result: Result<CarouselAdsResponse, AdChainError>) in
            switch result {
            case .success(let response):
                completion(.success(response.ads))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func trackEvent(_ event: AnalyticsEvent) {
        let endpoint = "/v1/analytics/event"
        
        post(endpoint: endpoint, body: event) { (result: Result<EmptyResponse, AdChainError>) in
            if case .failure(let error) = result {
                Logger.shared.log("Failed to track event: \(event.name), error: \(error)", level: .error)
                EventQueue.shared.add(event)
            }
        }
    }
    
    func flushPendingRequests() {
        EventQueue.shared.flush { [weak self] events in
            events.forEach { event in
                self?.trackEvent(event)
            }
        }
    }
    
    // MARK: - Private methods
    
    private func get<T: Decodable>(
        endpoint: String,
        parameters: [String: String] = [:],
        completion: @escaping (Result<T, AdChainError>) -> Void
    ) {
        var components = URLComponents(string: "\(config.actualBaseUrl)\(endpoint)")!
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = components.url else {
            completion(.failure(.invalidConfig(message: "Invalid URL")))
            return
        }
        
        let request = URLRequest(url: url)
        
        performRequest(request, completion: completion)
    }
    
    private func post<T: Decodable, U: Encodable>(
        endpoint: String,
        body: U,
        completion: @escaping (Result<T, AdChainError>) -> Void
    ) {
        guard let url = URL(string: "\(config.actualBaseUrl)\(endpoint)") else {
            completion(.failure(.invalidConfig(message: "Invalid URL")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            completion(.failure(.unknown(message: "Failed to encode request body", underlyingError: error)))
            return
        }
        
        performRequest(request, completion: completion)
    }
    
    private func performRequest<T: Decodable>(
        _ request: URLRequest,
        completion: @escaping (Result<T, AdChainError>) -> Void
    ) {
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(.networkError(message: error.localizedDescription, statusCode: nil)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.networkError(message: "Invalid response", statusCode: nil)))
                return
            }
            
            if httpResponse.statusCode == 204 || data?.isEmpty == true {
                if T.self == EmptyResponse.self {
                    completion(.success(EmptyResponse() as! T))
                } else {
                    completion(.failure(.networkError(message: "Empty response", statusCode: httpResponse.statusCode)))
                }
                return
            }
            
            guard let data = data else {
                completion(.failure(.networkError(message: "No data", statusCode: httpResponse.statusCode)))
                return
            }
            
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                do {
                    let result = try self?.decoder.decode(T.self, from: data)
                    completion(.success(result!))
                } catch {
                    completion(.failure(.unknown(message: "Failed to decode response", underlyingError: error)))
                }
            } else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                completion(.failure(.networkError(message: message, statusCode: httpResponse.statusCode)))
            }
        }
        
        task.resume()
    }
}

// MARK: - Response Models

internal struct EmptyResponse: Decodable {}

internal struct ValidateResponse: Decodable {
    let success: Bool
    let app: AppInfo?
    
    struct AppInfo: Decodable {
        let id: String
        let name: String
        let isActive: Bool
        let webOfferwallUrl: String?
    }
}

internal struct CarouselAdsResponse: Decodable {
    let ads: [CarouselAdResponse]
}

internal struct CarouselAdResponse: Decodable {
    let id: String
    let title: String
    let description: String?
    let imageUrl: String
    let landingUrl: String
    let metadata: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case imageUrl = "image_url"
        case landingUrl = "landing_url"
        case metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        imageUrl = try container.decode(String.self, forKey: .imageUrl)
        landingUrl = try container.decode(String.self, forKey: .landingUrl)
        
        if let metadataData = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
            metadata = metadataData.mapValues { $0.value }
        } else {
            metadata = nil
        }
    }
}

internal struct AnalyticsEvent: Encodable {
    let name: String
    let timestamp: TimeInterval
    let sessionId: String
    let userId: String?
    let deviceId: String
    let advertisingId: String?
    let os: String
    let osVersion: String
    let parameters: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case timestamp
        case sessionId = "session_id"
        case userId = "user_id"
        case deviceId = "device_id"
        case advertisingId = "advertising_id"
        case os
        case osVersion = "os_version"
        case parameters
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encodeIfPresent(advertisingId, forKey: .advertisingId)
        try container.encode(os, forKey: .os)
        try container.encode(osVersion, forKey: .osVersion)
        
        if let parameters = parameters {
            let anyCodableParams = parameters.mapValues { AnyCodable($0) }
            try container.encode(anyCodableParams, forKey: .parameters)
        }
    }
}

// Helper for encoding/decoding Any types
internal struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Unable to encode value"))
        }
    }
}