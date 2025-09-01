import XCTest
@testable import AdchainSDK

final class LocalServerTests: XCTestCase {
    
    // MARK: - Properties
    
    var sdk: AdchainSDK!
    var config: AdchainConfig!
    let localServerURL = "http://localhost:3000"
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        // Check if local server is running
        guard isLocalServerRunning() else {
            XCTSkip("Local server is not running. Start it with 'npm run start:local'")
            return
        }
        
        // Setup SDK with local server configuration
        config = AdchainConfig(
            appId: "test-app",
            appSecret: "test-secret",
            environment: .custom(baseURL: localServerURL)
        )
        
        sdk = AdchainSDK(config: config)
        
        // Reset and seed test data
        resetTestData()
        seedTestData()
    }
    
    override func tearDown() {
        sdk = nil
        config = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func isLocalServerRunning() -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var isRunning = false
        
        guard let url = URL(string: "\(localServerURL)/health") else { return false }
        
        let task = URLSession.shared.dataTask(with: url) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                isRunning = true
            }
            semaphore.signal()
        }
        
        task.resume()
        _ = semaphore.wait(timeout: .now() + 2.0)
        
        return isRunning
    }
    
    private func resetTestData() {
        let semaphore = DispatchSemaphore(value: 0)
        
        guard let url = URL(string: "\(localServerURL)/v1/test/reset") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { _, _, _ in
            semaphore.signal()
        }
        
        task.resume()
        _ = semaphore.wait(timeout: .now() + 2.0)
    }
    
    private func seedTestData() {
        let semaphore = DispatchSemaphore(value: 0)
        
        guard let url = URL(string: "\(localServerURL)/v1/test/seed") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { _, _, _ in
            semaphore.signal()
        }
        
        task.resume()
        _ = semaphore.wait(timeout: .now() + 2.0)
    }
    
    private func loadScenario(_ scenario: String) {
        let semaphore = DispatchSemaphore(value: 0)
        
        guard let url = URL(string: "\(localServerURL)/v1/test/seed/\(scenario)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { _, _, _ in
            semaphore.signal()
        }
        
        task.resume()
        _ = semaphore.wait(timeout: .now() + 2.0)
    }
    
    // MARK: - Tests
    
    func testRealServerConnection() {
        XCTAssertNotNil(sdk, "SDK should be initialized")
        XCTAssertTrue(isLocalServerRunning(), "Local server should be running")
    }
    
    func testRealServerFetchCarouselAds() {
        let expectation = self.expectation(description: "Fetch carousel ads from real server")
        
        sdk.carousel.fetchAds(unitId: "test-unit-001", count: 3) { result in
            switch result {
            case .success(let ads):
                XCTAssertFalse(ads.isEmpty, "Should return some ads")
                XCTAssertLessThanOrEqual(ads.count, 3, "Should not return more than requested")
                
                for ad in ads {
                    XCTAssertFalse(ad.id.isEmpty, "Ad should have ID")
                    XCTAssertFalse(ad.title.isEmpty, "Ad should have title")
                    XCTAssertFalse(ad.imageUrl.isEmpty, "Ad should have image URL")
                    XCTAssertFalse(ad.landingUrl.isEmpty, "Ad should have landing URL")
                }
                
            case .failure(let error):
                XCTFail("Should not fail: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testRealServerFetchDifferentUnit() {
        let expectation = self.expectation(description: "Fetch ads for different unit")
        
        sdk.carousel.fetchAds(unitId: "test-unit-002", count: 5) { result in
            switch result {
            case .success(let ads):
                // May or may not have ads depending on seed data
                XCTAssertNotNil(ads, "Should return a list (possibly empty)")
            case .failure(let error):
                XCTFail("Should not fail: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testRealServerTrackEvent() {
        let expectation = self.expectation(description: "Track event to real server")
        
        sdk.analytics.trackEvent(
            "integration_test_event",
            parameters: [
                "test": true,
                "timestamp": Date().timeIntervalSince1970,
                "source": "ios_sdk_test"
            ]
        )
        
        // Since tracking is fire-and-forget, wait a bit and check no crash
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // If we reach here without crash, test passes
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testRealServerMultipleRequests() {
        let expectation = self.expectation(description: "Multiple requests to real server")
        let group = DispatchGroup()
        var successCount = 0
        
        for i in 0..<3 {
            group.enter()
            
            sdk.carousel.fetchAds(unitId: "test-unit-001", count: 2) { result in
                if case .success = result {
                    successCount += 1
                }
                group.leave()
            }
            
            sdk.analytics.trackEvent(
                "test_event_\(i)",
                parameters: ["index": i]
            )
        }
        
        group.notify(queue: .main) {
            XCTAssertEqual(successCount, 3, "All requests should succeed")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testScenarioEmpty() {
        loadScenario("empty")
        
        let expectation = self.expectation(description: "Empty scenario")
        
        sdk.carousel.fetchAds(unitId: "test-unit-001", count: 10) { result in
            switch result {
            case .success(let ads):
                XCTAssertTrue(ads.isEmpty, "Should return empty list for empty scenario")
            case .failure(let error):
                XCTFail("Should not fail: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testScenarioManyAds() {
        loadScenario("many-ads")
        
        let expectation = self.expectation(description: "Many ads scenario")
        
        sdk.carousel.fetchAds(unitId: "test-unit-001", count: 10) { result in
            switch result {
            case .success(let ads):
                XCTAssertEqual(ads.count, 10, "Should return exactly 10 ads")
            case .failure(let error):
                XCTFail("Should not fail: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testScenarioMixedStatus() {
        loadScenario("mixed-status")
        
        let expectation = self.expectation(description: "Mixed status scenario")
        
        sdk.carousel.fetchAds(unitId: "test-unit-001", count: 10) { result in
            switch result {
            case .success(let ads):
                // Should only return active ads (2 based on scenario)
                XCTAssertEqual(ads.count, 2, "Should return only active ads")
            case .failure(let error):
                XCTFail("Should not fail: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testRealServerPerformance() {
        measure {
            let expectation = self.expectation(description: "Performance test")
            
            sdk.carousel.fetchAds(unitId: "test-unit-001", count: 5) { _ in
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
    }
}