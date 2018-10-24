import XCTest
import SQLite3
@testable import SQLCodable

class SQLDatabaseTests: XCTestCase {
    let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        .appendingPathComponent("SQLCodableTests.sqlite")

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    struct Person: Equatable, SQLCodable {
        let id: UInt32
        let name: String?

        static let primaryKey: [CodingKey] = [ CodingKeys.id, CodingKeys.name ]
        static let indexes = [
            SQLIndex("id", on: [ CodingKeys.id ]),
            SQLIndex("uname", on: [ CodingKeys.name, CodingKeys.id ], unique: true),
        ]

        static func hasID(_ id: UInt32) -> SQLWhere {
            return .is(CodingKeys.id, .equalTo, .value(id))
        }

        static let byName: [SQLOrder] = [.atoz(CodingKeys.name)]
    }

    struct NoPrimary: SQLCodable {}

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

    func testInsert() {
        let db = SQLDatabase(at: fileURL)
        let person1 = Person(id: 1, name: "John Doe")
        let person2 = Person(id: 2, name: "Fulano de Tal")
        XCTAssertNoThrow(try db.create(table: SQLTable(for: Person.self)))
        XCTAssertNoThrow(try db.insert(person1))
        XCTAssertThrowsError(try db.insert(person1)) // duplicate
        XCTAssertNoThrow(try db.insert(person2))
        XCTAssertEqual(try db.select(Person.self), [person1, person2])
    }

    func testSelect() {
        let db = SQLDatabase(at: fileURL)
        let person1 = Person(id: 1, name: "John Doe")
        let person2 = Person(id: 2, name: "Fulano de Tal")
        XCTAssertNoThrow(try db.create(table: SQLTable(for: Person.self)))
        XCTAssertNoThrow(try db.insert(person1))
        XCTAssertNoThrow(try db.insert(person2))
        XCTAssertEqual(try db.select(Person.self, order: Person.byName), [person2, person1])
        XCTAssertEqual(try db.select(Person.self, limit: 1), [person1])
        XCTAssertEqual(try db.select(Person.self, limit: 1, offset: 1), [person2])
        XCTAssertEqual(try db.select(Person.self, order: Person.byName, limit: 1), [person2])
        XCTAssertEqual(try db.select(Person.self, order: Person.byName, limit: 1, offset: 1), [person1])
        XCTAssertEqual(try db.select(Person.self, where: Person.hasID(1)), [person1]) // no duplicates
    }

    func testDelete() {
        let db = SQLDatabase(at: fileURL)
        let person1 = Person(id: 1, name: "John Doe")
        let person2 = Person(id: 2, name: "Fulano de Tal")
        let person3 = Person(id: 3, name: nil)
        XCTAssertNoThrow(try db.create(table: SQLTable(for: Person.self)))

        XCTAssertNoThrow(try db.insert(person1))
        XCTAssertNoThrow(try db.insert(person2))
        XCTAssertNoThrow(try db.insert(person3))
        XCTAssertEqual(try db.delete(person3), 1)
        XCTAssertEqual(try db.delete(person3), 0)
        XCTAssertEqual(try db.delete(Person.self, where: Person.hasID(3)), 0)
        XCTAssertEqual(try db.delete(Person.self, where: Person.hasID(1)), 1)
        XCTAssertEqual(try db.select(Person.self), [person2])

        XCTAssertNoThrow(try db.insert(person1))
        XCTAssertNoThrow(try db.insert(person3))
        XCTAssertEqual(try db.delete(Person.self), 3)
        XCTAssertEqual(try db.select(Person.self), [])

        XCTAssertThrowsError(try db.delete(NoPrimary()))
    }
}
