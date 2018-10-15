import XCTest
@testable import SQLCodable

class SQLDatabaseTests: XCTestCase {
    let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        .appendingPathComponent("SQLCodableTests.sqlite")

    override func tearDown() {
        try! FileManager.default.removeItem(at: fileURL)
    }

    struct Person: SQLCodable {
        let id: UInt32
        let name: String?

        static let primaryKey = CodingKeys.id.stringValue
    }

    func testCreate() {
        let db = SQLDatabase(at: fileURL)
        XCTAssertNoThrow(try db.create(table: SQLTable(for: Person.self)))
        XCTAssertEqual(try db.query("SELECT sql FROM sqlite_master WHERE name = 'Person'")[0]["sql"], SQLValue.text("CREATE TABLE Person (id INTEGER NOT NULL, name TEXT NULL, PRIMARY KEY (id))"))
    }
}
