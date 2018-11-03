import Foundation
import SQLite3

internal let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

func id(_ id: String) -> String {
    return "\"\(id.replacingOccurrences(of: "\"", with: "\"\""))\""
}

func id(_ key: CodingKey) -> String {
    return id(key.stringValue)
}

public enum SQLParameter {
    case null
    case blob(Data)
    case int(Int64)
    case real(Double)
    case text(String)

    public static func value(_ value: Data)   -> SQLParameter { return .blob(value) }
    public static func value(_ value: String) -> SQLParameter { return .text(value) }
    public static func value(_ value: Double) -> SQLParameter { return .real(value) }
    public static func value(_ value: Float)  -> SQLParameter { return .real(Double(value)) }
    public static func value(_ value: Bool)   -> SQLParameter { return .int(value ? -1 : 0) }
    public static func value(_ value: Int)    -> SQLParameter { return .int(Int64(value)) }
    public static func value(_ value: Int8)   -> SQLParameter { return .int(Int64(value)) }
    public static func value(_ value: Int16)  -> SQLParameter { return .int(Int64(value)) }
    public static func value(_ value: Int32)  -> SQLParameter { return .int(Int64(value)) }
    public static func value(_ value: Int64)  -> SQLParameter { return .int(value) }
    public static func value(_ value: UInt)   -> SQLParameter { return .int(Int64(value)) }
    public static func value(_ value: UInt8)  -> SQLParameter { return .int(Int64(value)) }
    public static func value(_ value: UInt16) -> SQLParameter { return .int(Int64(value)) }
    public static func value(_ value: UInt32) -> SQLParameter { return .int(Int64(value)) }
    public static func value(_ value: UInt64) -> SQLParameter { return .int(Int64(value)) }

    func bind(to statement: OpaquePointer?, index: Int32) -> Int32 {
        switch self {
        case .null:
            return sqlite3_bind_null(statement, index)
        case .blob(let value):
            return value.withUnsafeBytes { bytes in
                sqlite3_bind_blob(statement, index, bytes, Int32(value.count), SQLITE_TRANSIENT)
            }
        case .int(let value):
            return sqlite3_bind_int64(statement, index, value)
        case .real(let value):
            return sqlite3_bind_double(statement, index, value)
        case .text(let value):
            return sqlite3_bind_text(statement, index, value, -1, SQLITE_TRANSIENT)
        }
    }
}
