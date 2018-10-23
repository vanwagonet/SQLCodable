import Foundation

public struct SQLColumn: Equatable {
    public let type: SQLColumnType
    public let null: Bool
}

public enum SQLColumnType: String, Codable {
    case blob = "BLOB"
    case int  = "INTEGER"
    case real = "REAL"
    case text = "TEXT"
}

// PRAGMA table_info
struct SQLColumnInfo: Decodable {
    let name: String
    let notnull: Bool
    let pk: Int
    let type: SQLColumnType
}
