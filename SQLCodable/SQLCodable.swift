import Foundation

public protocol SQLCodable: Codable {
    static var primaryKey: String { get }
    static var tableName: String { get }
}

extension SQLCodable {
    public static var tableName: String {
        return String(describing: Self.self)
    }
}
