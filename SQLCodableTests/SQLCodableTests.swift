import XCTest
@testable import SQLCodable

class SQLCodableTests: XCTestCase {
    struct Model: SQLCodable {
        let id: UInt = 1

        static var primaryKey = CodingKeys.id.stringValue
    }

    func testTableName() {
        XCTAssertEqual(Model.tableName, "Model")
    }
}
