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

        static let primaryKey: [CodingKey] = [ CodingKeys.id, CodingKeys.name ]
        static let indexes: [SQLIndex] = [
            .index("id", on: [ CodingKeys.id ]),
            .index("uname", on: [ CodingKeys.name, CodingKeys.id ], unique: true),
        ]
    }

    func testCreateTable() {
        let db = SQLDatabase(at: fileURL)
        let table = try! SQLTable(for: Person.self)
        XCTAssertNil(try db.table(for: Person.self))
        XCTAssertNoThrow(try db.create(table: table))
        XCTAssertEqual(try db.table(for: Person.self), table)
    }
}
