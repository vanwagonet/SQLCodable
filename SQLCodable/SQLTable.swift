import Foundation

public struct SQLTable: Equatable {
    public let columns: Set<SQLColumn>
    public let primaryKey: SQLColumn
    public let name: String

    public init(columns: Set<SQLColumn>, primaryKey: SQLColumn, name: String) {
        self.columns = columns
        self.primaryKey = primaryKey
        self.name = name
    }

    public init<Model: SQLCodable>(for type: Model.Type) throws {
        columns = try SQLTableDecoder().decode(Model.self)
        guard let primary = columns.first(where: { $0.name == Model.primaryKey }) else {
            throw NSError(domain: "SQLCodable", code: 1, userInfo: nil)
        }
        primaryKey = primary
        name = Model.tableName
    }
}

public struct SQLColumn: Equatable, Hashable {
    public let name: String
    public let optional: Bool
    public let type: SQLColumnType

    private static var placeholders: [String: Decodable] = [:]

    public static func register<Field: Decodable>(placeholder: Field) {
        placeholders[String(describing: Field.self)] = placeholder
    }

    internal static func placeholder<Field: Decodable>(for: Field.Type) -> Field? {
        guard let placeholder = placeholders[String(describing: Field.self)] else { return nil }
        return placeholder as? Field
    }
}

public enum SQLColumnType: String {
    case blob, int, real, text
}
