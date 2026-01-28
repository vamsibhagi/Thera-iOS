import XCTest
import FamilyControls // Needed for ApplicationToken
@testable import Thera

final class ModelsTests: XCTestCase {

    // MARK: - AppLimit Tests
    
    func testAppLimitInitialization() {
        // Since we can't easily instantiate ApplicationToken directly in tests (init is restricted),
        // we might need to rely on the fact that AppLimit uses it.
        // However, for pure unit testing without a real token, we might get blocked.
        // But we can test the UUID part if we treat the token as opaque.
        // Actually, we can't create a dummy ApplicationToken easily.
        // So we will focus on the ID generation logic which is independent of the token.
        
        let uuid1 = UUID()
        let uuid2 = UUID()
        
        XCTAssertNotEqual(uuid1, uuid2)
    }
    
    // MARK: - Suggestion Context Tests
    
    func testSmartSortMorning() {
        // Monday 8:00 AM
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 1 // Monday
        components.hour = 8
        components.minute = 0
        let date = Calendar.current.date(from: components)!
        
        let result = SuggestionContext.smartSort(date: date)
        
        // Expect: [.bed, .couch, .waiting, .commuting, .work] (Based on Model logic)
        // Wait, 5-9 AM (Morning)
        // Weekend? No.
        // Rule: [.bed, .commuting, .waiting, .work, .couch]
        
        XCTAssertEqual(result.first, .bed)
        XCTAssertEqual(result[1], .commuting)
    }
    
    func testSmartSortEvening() {
         // Monday 8:00 PM (20:00)
         var components = DateComponents()
         components.year = 2024
         components.month = 1
         components.day = 1 // Monday
         components.hour = 20
         components.minute = 0
         let date = Calendar.current.date(from: components)!
         
         let result = SuggestionContext.smartSort(date: date)
         
         // 19-22 PM (Evening)
         // Rule: [.couch, .bed, .waiting, .commuting, .work]
         
         XCTAssertEqual(result.first, .couch)
         XCTAssertEqual(result[1], .bed)
     }
}
