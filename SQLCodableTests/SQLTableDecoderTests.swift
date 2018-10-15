import XCTest
@testable import SQLCodable

class SQLTableDecoderTests: XCTestCase {
    struct Strings: SQLCodable {
        let string: String
        let optional: String?

        static let primaryKey = CodingKeys.string.stringValue
    }
    func testStrings() {
        XCTAssertEqual(try SQLTable(for: Strings.self), SQLTable(
            columns: [
                SQLColumn(name: "string",   optional: false, type: .text),
                SQLColumn(name: "optional", optional: true,  type: .text),
            ],
            primaryKey: SQLColumn(name: "string", optional: false, type: .text),
            name: "Strings"
        ))
    }

    struct Floats: SQLCodable {
        let float: Float
        let double: Double
        let ofloat: Float?
        let odouble: Double?

        static let primaryKey = CodingKeys.float.stringValue
    }
    func testFloats() {
        XCTAssertEqual(try SQLTable(for: Floats.self), SQLTable(
            columns: [
                SQLColumn(name: "float",   optional: false, type: .real),
                SQLColumn(name: "double",  optional: false, type: .real),
                SQLColumn(name: "ofloat",  optional: true,  type: .real),
                SQLColumn(name: "odouble", optional: true,  type: .real),
            ],
            primaryKey: SQLColumn(name: "float", optional: false, type: .real),
            name: "Floats"
        ))
    }

    struct Bools: SQLCodable {
        let bool: Bool
        let optional: Bool?

        static let primaryKey = CodingKeys.bool.stringValue
    }
    func testBools() {
        XCTAssertEqual(try SQLTable(for: Bools.self), SQLTable(
            columns: [
                SQLColumn(name: "bool",     optional: false, type: .int),
                SQLColumn(name: "optional", optional: true,  type: .int),
            ],
            primaryKey: SQLColumn(name: "bool", optional: false, type: .int),
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

        static let primaryKey = CodingKeys.i.stringValue
    }
    func testIntegers() {
        XCTAssertEqual(try SQLTable(for: Integers.self), SQLTable(
            columns: [
                SQLColumn(name: "i",    optional: false, type: .int),
                SQLColumn(name: "i8",   optional: false, type: .int),
                SQLColumn(name: "i16",  optional: false, type: .int),
                SQLColumn(name: "i32",  optional: false, type: .int),
                SQLColumn(name: "i64",  optional: false, type: .int),
                SQLColumn(name: "u",    optional: false, type: .int),
                SQLColumn(name: "u8",   optional: false, type: .int),
                SQLColumn(name: "u16",  optional: false, type: .int),
                SQLColumn(name: "u32",  optional: false, type: .int),
                SQLColumn(name: "u64",  optional: false, type: .int),
                SQLColumn(name: "oi",   optional: true,  type: .int),
                SQLColumn(name: "oi8",  optional: true,  type: .int),
                SQLColumn(name: "oi16", optional: true,  type: .int),
                SQLColumn(name: "oi32", optional: true,  type: .int),
                SQLColumn(name: "oi64", optional: true,  type: .int),
                SQLColumn(name: "ou",   optional: true,  type: .int),
                SQLColumn(name: "ou8",  optional: true,  type: .int),
                SQLColumn(name: "ou16", optional: true,  type: .int),
                SQLColumn(name: "ou32", optional: true,  type: .int),
                SQLColumn(name: "ou64", optional: true,  type: .int),
            ],
            primaryKey: SQLColumn(name: "i", optional: false, type: .int),
            name: "Integers"
        ))
    }

    enum IntEnum: Int, Codable { case one = 1, two }
    enum StringEnum: String, Codable { case abcd, efgh }
    struct Enums: SQLCodable {
        let ie: IntEnum
        let se: StringEnum
        let oie: IntEnum?
        let ose: StringEnum?

        static let primaryKey = CodingKeys.ie.stringValue
    }
    func testEnums() {
        SQLColumn.register(placeholder: StringEnum.abcd)
        XCTAssertEqual(try SQLTable(for: Enums.self), SQLTable(
            columns: [
                SQLColumn(name: "ie",  optional: false, type: .int),
                SQLColumn(name: "se",  optional: false, type: .text),
                SQLColumn(name: "oie", optional: true,  type: .int),
                SQLColumn(name: "ose", optional: true,  type: .text),
            ],
            primaryKey: SQLColumn(name: "ie", optional: false, type: .int),
            name: "Enums"
        ))
    }

    struct Options: OptionSet, Codable {
        let rawValue: UInt8

        static let a = Options(rawValue: 1 << 0)
        static let b = Options(rawValue: 1 << 1)
        static let c = Options(rawValue: 1 << 2)
        static let d = Options(rawValue: 1 << 3)
    }
    struct OptionSets: SQLCodable {
        let o: Options
        let oo: Options?

        static let primaryKey = CodingKeys.o.stringValue
    }
    func testOptionSets() {
        XCTAssertEqual(try SQLTable(for: OptionSets.self), SQLTable(
            columns: [
                SQLColumn(name: "o",  optional: false, type: .int),
                SQLColumn(name: "oo", optional: true,  type: .int),
            ],
            primaryKey: SQLColumn(name: "o", optional: false, type: .int),
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

        static let primaryKey = CodingKeys.astr.stringValue
    }
    func testArrays() {
        XCTAssertEqual(try SQLTable(for: Arrays.self), SQLTable(
            columns: [
                SQLColumn(name: "astr",  optional: false, type: .text),
                SQLColumn(name: "oastr", optional: true,  type: .text),
                SQLColumn(name: "aostr", optional: false, type: .text),
                SQLColumn(name: "aint",  optional: false, type: .text),
                SQLColumn(name: "oaint", optional: true,  type: .text),
                SQLColumn(name: "aoint", optional: false, type: .text),
            ],
            primaryKey: SQLColumn(name: "astr", optional: false, type: .text),
            name: "Arrays"
        ))
    }

    struct Inside: Codable {
        let v: [String]
    }
    struct NestedStructs: SQLCodable {
        let s: Inside
        let os: Inside?

        static let primaryKey = CodingKeys.s.stringValue
    }
    func testNestedStructs() {
        XCTAssertEqual(try SQLTable(for: NestedStructs.self), SQLTable(
            columns: [
                SQLColumn(name: "s",  optional: false, type: .text),
                SQLColumn(name: "os", optional: true,  type: .text),
            ],
            primaryKey: SQLColumn(name: "s", optional: false, type: .text),
            name: "NestedStructs"
        ))
    }
}
