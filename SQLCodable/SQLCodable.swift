import Foundation

public protocol SQLCodable: Codable {
    static var indexes: [SQLIndex] { get }
    static var primaryKey: [CodingKey] { get }
    static var tableName: String { get }
}

extension SQLCodable {
    public static var indexes: [SQLIndex] {
        return []
    }

    public static var primaryKey: [CodingKey] {
        return []
    }

    public static var tableName: String {
        return String(describing: Self.self)
    }
}
