import XCTest
@testable import SQLCodable

class SQLTableDecoderTests: XCTestCase {
    struct Strings: SQLCodable {
        let string: String
        let ostring: String?
    }
    func testStrings() {
        XCTAssertEqual(try SQLTable(for: Strings.self), SQLTable(
            columns: [
                "string":  SQLColumn(type: .text, null: false),
                "ostring": SQLColumn(type: .text, null: true),
            ],
            name: "Strings"
        ))
    }

    struct Floats: SQLCodable {
        let float: Float
        let double: Double
        let ofloat: Float?
        let odouble: Double?
        let date: Date
        let odate: Date?
    }
    func testFloats() {
        XCTAssertEqual(try SQLTable(for: Floats.self), SQLTable(
            columns: [
                "float":   SQLColumn(type: .real, null: false),
                "double":  SQLColumn(type: .real, null: false),
                "ofloat":  SQLColumn(type: .real, null: true),
                "odouble": SQLColumn(type: .real, null: true),
                "date":    SQLColumn(type: .real, null: false),
                "odate":   SQLColumn(type: .real, null: true),
            ],
            name: "Floats"
        ))
    }

    struct Bools: SQLCodable {
        let bool: Bool
        let optional: Bool?
    }
    func testBools() {
        XCTAssertEqual(try SQLTable(for: Bools.self), SQLTable(
            columns: [
                "bool":     SQLColumn(type: .int, null: false),
                "optional": SQLColumn(type: .int, null: true),
            ],
            name: "Bools"
        ))
    }

    struct Integers: SQLCodable {
        let i: Int
        let i8: Int8
        let i16: Int16
        let i32: Int32
        let i64: Int64
        let u: UInt
        let u8: UInt8
        let u16: UInt16
        let u32: UInt32
        let u64: UInt64
        let oi: Int?
        let oi8: Int8?
        let oi16: Int16?
        let oi32: Int32?
        let oi64: Int64?
        let ou: UInt?
        let ou8: UInt8?
        let ou16: UInt16?
        let ou32: UInt32?
        let ou64: UInt64?
    }
    func testIntegers() {
        XCTAssertEqual(try SQLTable(for: Integers.self), SQLTable(
            columns: [
                "i":    SQLColumn(type: .int, null: false),
                "i8":   SQLColumn(type: .int, null: false),
                "i16":  SQLColumn(type: .int, null: false),
                "i32":  SQLColumn(type: .int, null: false),
                "i64":  SQLColumn(type: .int, null: false),
                "u":    SQLColumn(type: .int, null: false),
                "u8":   SQLColumn(type: .int, null: false),
                "u16":  SQLColumn(type: .int, null: false),
                "u32":  SQLColumn(type: .int, null: false),
                "u64":  SQLColumn(type: .int, null: false),
                "oi":   SQLColumn(type: .int, null: true),
                "oi8":  SQLColumn(type: .int, null: true),
                "oi16": SQLColumn(type: .int, null: true),
                "oi32": SQLColumn(type: .int, null: true),
                "oi64": SQLColumn(type: .int, null: true),
                "ou":   SQLColumn(type: .int, null: true),
                "ou8":  SQLColumn(type: .int, null: true),
                "ou16": SQLColumn(type: .int, null: true),
                "ou32": SQLColumn(type: .int, null: true),
                "ou64": SQLColumn(type: .int, null: true),
            ],
            name: "Integers"
        ))
    }

    enum IntEnum: Int, Codable { case one, two }
    enum StringEnum: String, Codable { case abcd, efgh }
    struct Enums: SQLCodable {
        let ie: IntEnum
        let se: StringEnum
        let oie: IntEnum?
        let ose: StringEnum?
    }
    func testEnums() {
        XCTAssertThrowsError(try SQLTable(for: Enums.self)) { error in
            if case .missingPlaceholder(let missing) = error as! SQLError {
                XCTAssert(missing is StringEnum.Type)
            }
        }

        SQLTable.register(placeholder: StringEnum.abcd)
        XCTAssertEqual(try SQLTable(for: Enums.self), SQLTable(
            columns: [
                "ie":  SQLColumn(type: .int,  null: false),
                "se":  SQLColumn(type: .text, null: false),
                "oie": SQLColumn(type: .int,  null: true),
                "ose": SQLColumn(type: .text, null: true),
            ],
            name: "Enums"
        ))
    }

    struct Options: OptionSet, Codable {
        let rawValue: UInt8
        static let a = Options(rawValue: 1 << 0)
        static let b = Options(rawValue: 1 << 1)
    }
    struct OptionSets: SQLCodable {
        let o: Options
        let oo: Options?
    }
    func testOptionSets() {
        XCTAssertEqual(try SQLTable(for: OptionSets.self), SQLTable(
            columns: [
                "o":  SQLColumn(type: .int, null: false),
                "oo": SQLColumn(type: .int, null: true),
            ],
            name: "OptionSets"
        ))
    }

    struct Arrays: SQLCodable {
        let astr: [String]
        let oastr: [String]?
        let aostr: [String?]
        let aint: [Int]
        let oaint: [Int]?
        let aoint: [Int?]
    }
    func testArrays() {
        XCTAssertEqual(try SQLTable(for: Arrays.self), SQLTable(
            columns: [
                "astr":  SQLColumn(type: .text, null: false),
                "oastr": SQLColumn(type: .text, null: true),
                "aostr": SQLColumn(type: .text, null: false),
                "aint":  SQLColumn(type: .text, null: false),
                "oaint": SQLColumn(type: .text, null: true),
                "aoint": SQLColumn(type: .text, null: false),
            ],
            name: "Arrays"
        ))
    }

    struct Inside: Codable {
        let v: [String]
    }
    struct NestedStructs: SQLCodable {
        let s: Inside
        let os: Inside?
    }
    func testNestedStructs() {
        XCTAssertEqual(try SQLTable(for: NestedStructs.self), SQLTable(
            columns: [
                "s":  SQLColumn(type: .text, null: false),
                "os": SQLColumn(type: .text, null: true),
            ],
            name: "NestedStructs"
        ))
    }
}
