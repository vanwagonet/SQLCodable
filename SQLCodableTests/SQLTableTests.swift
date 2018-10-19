import XCTest
@testable import SQLCodable

class SQLTableTests: XCTestCase {
    enum BadKeys: CodingKey {
        case primary, index
    }
    struct BadKeyHaver: SQLCodable {
        static let primaryKey: [CodingKey] = [BadKeys.primary]
        static let indexes: [SQLIndex] = [
            .index("bad", on: [BadKeys.index])
        ]
    }
    func testBadPrimaryKey() {
        XCTAssertThrowsError(try SQLTable(for: BadKeyHaver.self)) { error in
            if case .invalidColumns(let invalids) = error as! SQLError {
                XCTAssertEqual(invalids, [ "index", "primary" ])
            }
        }
    }
}
