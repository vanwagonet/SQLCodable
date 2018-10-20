import XCTest
import SQLite3
@testable import SQLCodable

class SQLDatabaseTests: XCTestCase {
    let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        .appendingPathComponent("SQLCodableTests.sqlite")

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    struct Person: SQLCodable {
        let id: UInt32
        let name: String?

        static let primaryKey: [CodingKey] = [ CodingKeys.id, CodingKeys.name ]
        static let indexes = [
            SQLIndex("id", on: [ CodingKeys.id ]),
            SQLIndex("uname", on: [ CodingKeys.name, CodingKeys.id ], unique: true),
        ]
    }

    func testCheck() {
        let db = SQLDatabase(at: fileURL)
        XCTAssertThrowsError(try db.check(5))
    }

    func testDisconnect() {
        let db = SQLDatabase(at: fileURL)
        XCTAssertNoThrow(try db.disconnect())
        try! db.connect()
        XCTAssertNoThrow(try db.disconnect())
    }

    func testQueryError() {
        let db = SQLDatabase(at: fileURL)
        XCTAssertThrowsError(try db.query([String: String].self, sql: "")) { error in
            if case .sqliteError(let code, let msg) = error as! SQLError {
                XCTAssertEqual(code, SQLITE_MISUSE)
                XCTAssertEqual(msg, "not an error")
            }
        }
    }

    func testCreateTable() {
        let db = SQLDatabase(at: fileURL)
        let table = try! SQLTable(for: Person.self)
        XCTAssertNil(try db.table(for: Person.self))
        XCTAssertNoThrow(try db.create(table: table))
        XCTAssertEqual(try db.table(for: Person.self), table)
    }
}
