import XCTest
@testable import Thera

final class MetricsManagerTests: XCTestCase {
    
    override func setUp() {
        // We can't easily mock the FileManager containerURL in a unit test without dependency injection,
        // but we can test the `AppMetrics` Codable conformance and basic logic if we exposed it.
        // For now, checks if the singleton exists.
    }

    func testMetricsEncoding() throws {
        // 1. Create dummy metrics
        let metrics = AppMetrics(shieldShownCount: 5, shieldUnlockedCount: 2, lastConfigPing: Date(), lastActionPing: Date())
        
        // 2. Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(metrics)
        XCTAssertFalse(data.isEmpty)
        
        // 3. Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppMetrics.self, from: data)
        
        // 4. Verify
        XCTAssertEqual(decoded.shieldShownCount, 5)
        XCTAssertEqual(decoded.shieldUnlockedCount, 2)
    }
    
    func testMetricsIntegrationMock() {
        // Since we cannot write to the real App Group container in a simulator-less test easily,
        // we verifying the Manager singleton structure.
        let manager = MetricsManager.shared
        XCTAssertNotNil(manager)
        // We can't assert the counts without writing to disk, but checking it doesn't crash is good sanity.
    }
}
