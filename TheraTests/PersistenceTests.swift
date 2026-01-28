import XCTest
@testable import Thera

final class PersistenceTests: XCTestCase {

    @MainActor func testTaskItemEncoding() throws {
        let task = TaskItem(
            id: "123",
            text: "Test Task",
            emoji: "🧪",
            suggestionCategory: .offPhone,
            activityType: "Test",
            url: nil,
            isTheraSuggested: false,
            isCompleted: false,
            createdAt: Date()
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(task)
        
        XCTAssertFalse(data.isEmpty)
        
        let decoder = JSONDecoder()
        let decodedTask = try decoder.decode(TaskItem.self, from: data)
        
        XCTAssertEqual(task.id, decodedTask.id)
        XCTAssertEqual(task.text, decodedTask.text)
    }
}

