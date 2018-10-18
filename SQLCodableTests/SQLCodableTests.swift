import XCTest
@testable import SQLCodable

class SQLCodableTests: XCTestCase {
    struct Model: SQLCodable {
        let id: UInt = 1
    }

    func testIndexes() {
        XCTAssert(Model.indexes.isEmpty)
    }

    func testPrimaryKey() {
        XCTAssert(Model.primaryKey.isEmpty)
    }

    func testTableName() {
        XCTAssertEqual(Model.tableName, "Model")
    }
}
