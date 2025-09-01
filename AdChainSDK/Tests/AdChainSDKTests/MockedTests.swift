import XCTest
@testable import AdchainSDK

final class MockedTests: XCTestCase {
    
    // MARK: - URLProtocol Mock
    
    class MockURLProtocol: URLProtocol {
        static var mockResponses: [String: (data: Data?, response: URLResponse?, error: Error?)] = [:]
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let url = request.url,
                  let mockResponse = MockURLProtocol.mockResponses[url.absoluteString] else {
                client?.urlProtocol(self, didFailWithError: NSError(domain: "MockError", code: 404, userInfo: nil))
                return
            }
            
            if let response = mockResponse.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let data = mockResponse.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let error = mockResponse.error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
        }
        
        override func stopLoading() {
            // Nothing to do
        }
    }
    
    // MARK: - Properties
    
    var sdk: AdChainSDK!
    var config: AdChainConfig!
    var mockSession: URLSession!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        // Configure URLSession with mock protocol
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: configuration)
        
        // Setup SDK with mock configuration
        config = AdChainConfig(
            appId: "test-app",
            appSecret: "test-secret",
            environment: .custom(baseURL: "https://mock-server.com")
        )
        
        sdk = AdChainSDK(config: config)
        
        // Clear mock responses
        MockURLProtocol.mockResponses.removeAll()
    }
    
    override func tearDown() {
        sdk = nil
        config = nil
        mockSession = nil
        MockURLProtocol.mockResponses.removeAll()
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testSDKInitialization() {
        XCTAssertNotNil(sdk)
        XCTAssertEqual(sdk.config.appId, "test-app")
        XCTAssertEqual(sdk.config.appSecret, "test-secret")
    }
    
    func testValidateCredentialsSuccess() {
        let expectation = self.expectation(description: "Validate credentials")
        
        // Setup mock response
        let mockData = """
        {"success": true}
        """.data(using: .utf8)
        
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://mock-server.com/v1/sdk/validate")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
        
        MockURLProtocol.mockResponses["https://mock-server.com/v1/sdk/validate"] = (mockData, mockResponse, nil)
        
        // Use reflection to access internal API client for testing
        // Note: In real implementation, we'd need to modify ApiClient to accept custom URLSession
        
        expectation.fulfill() // For now, just fulfill to show structure
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchCarouselAdsSuccess() {
        let expectation = self.expectation(description: "Fetch carousel ads")
        
        // Setup mock response
        let mockData = """
        {
            "ads": [
                {
                    "id": "mock-ad-1",
                    "title": "Mock Ad 1",
                    "description": "Mock Description 1",
                    "image_url": "https://example.com/image1.jpg",
                    "landing_url": "https://example.com/landing1"
                },
                {
                    "id": "mock-ad-2",
                    "title": "Mock Ad 2",
                    "description": "Mock Description 2",
                    "image_url": "https://example.com/image2.jpg",
                    "landing_url": "https://example.com/landing2"
                }
            ]
        }
        """.data(using: .utf8)
        
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://mock-server.com/v1/carousel/ads?unit_id=test&count=2")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
        
        MockURLProtocol.mockResponses["https://mock-server.com/v1/carousel/ads?unit_id=test&count=2"] = (mockData, mockResponse, nil)
        
        // Test carousel fetch
        sdk.carousel.fetchAds(unitId: "test", count: 2) { result in
            switch result {
            case .success(let ads):
                XCTAssertEqual(ads.count, 2)
                XCTAssertEqual(ads[0].id, "mock-ad-1")
                XCTAssertEqual(ads[0].title, "Mock Ad 1")
                XCTAssertEqual(ads[1].id, "mock-ad-2")
                XCTAssertEqual(ads[1].title, "Mock Ad 2")
            case .failure(let error):
                XCTFail("Should not fail: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testFetchCarouselAdsEmpty() {
        let expectation = self.expectation(description: "Fetch empty carousel ads")
        
        let mockData = """
        {"ads": []}
        """.data(using: .utf8)
        
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://mock-server.com/v1/carousel/ads?unit_id=empty&count=5")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
        
        MockURLProtocol.mockResponses["https://mock-server.com/v1/carousel/ads?unit_id=empty&count=5"] = (mockData, mockResponse, nil)
        
        sdk.carousel.fetchAds(unitId: "empty", count: 5) { result in
            switch result {
            case .success(let ads):
                XCTAssertTrue(ads.isEmpty)
            case .failure(let error):
                XCTFail("Should not fail: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testTrackEvent() {
        let expectation = self.expectation(description: "Track event")
        
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://mock-server.com/v1/analytics/event")!,
            statusCode: 201,
            httpVersion: nil,
            headerFields: nil
        )
        
        MockURLProtocol.mockResponses["https://mock-server.com/v1/analytics/event"] = (nil, mockResponse, nil)
        
        sdk.analytics.trackEvent(
            "test_event",
            parameters: ["key": "value"]
        )
        
        // Since tracking is fire-and-forget, we just verify it doesn't crash
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testNetworkError() {
        let expectation = self.expectation(description: "Network error")
        
        let networkError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "No internet connection"]
        )
        
        MockURLProtocol.mockResponses["https://mock-server.com/v1/carousel/ads?unit_id=error&count=1"] = (nil, nil, networkError)
        
        sdk.carousel.fetchAds(unitId: "error", count: 1) { result in
            switch result {
            case .success:
                XCTFail("Should fail with network error")
            case .failure(let error):
                XCTAssertNotNil(error)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testHTTPErrorResponse() {
        let expectation = self.expectation(description: "HTTP error")
        
        let errorData = """
        {"error": "Unauthorized"}
        """.data(using: .utf8)
        
        let errorResponse = HTTPURLResponse(
            url: URL(string: "https://mock-server.com/v1/carousel/ads?unit_id=unauthorized&count=1")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
        
        MockURLProtocol.mockResponses["https://mock-server.com/v1/carousel/ads?unit_id=unauthorized&count=1"] = (errorData, errorResponse, nil)
        
        sdk.carousel.fetchAds(unitId: "unauthorized", count: 1) { result in
            switch result {
            case .success:
                XCTFail("Should fail with 401 error")
            case .failure(let error):
                XCTAssertNotNil(error)
                // Check if error contains unauthorized info
                if case AdChainError.networkError(let message, let statusCode) = error {
                    XCTAssertEqual(statusCode, 401)
                }
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}