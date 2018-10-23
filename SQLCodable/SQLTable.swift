import Foundation

public struct SQLTable: Equatable {
    public let columns: [String: SQLColumn]
    public let indexes: [SQLIndex]
    public let name: String
    public let primaryKey: [String]

    internal init(columns: [String: SQLColumn], indexes: [SQLIndex] = [], name: String, primaryKey: [String] = []) {
        self.columns = columns
        self.indexes = indexes.sorted(by: { $0.name < $1.name })
        self.name = name
        self.primaryKey = primaryKey.sorted()
    }

    public init<Model: SQLCodable>(for type: Model.Type) throws {
        self.columns = try SQLTableDecoder().decode(type)
        self.indexes = type.indexes.sorted(by: { $0.name < $1.name })
        self.name = type.tableName
        self.primaryKey = type.primaryKey.map { $0.stringValue } .sorted()
        let allKeys = self.indexes.flatMap { $0.columns } + self.primaryKey
        let invalidKeys = allKeys.filter { columns[$0] == nil }
        guard invalidKeys.isEmpty else { throw SQLError.invalidColumns(invalidKeys.sorted()) }
    }

    internal static var placeholders: [Any] = []

    public static func register<Field: Decodable>(placeholder value: Field) {
        if placeholder(for: Field.self) == nil { placeholders.append(value) }
    }

    internal static func placeholder<Field: Decodable>(for: Field.Type) -> Field? {
        return placeholders.first(where: { $0 is Field }) as? Field
    }
}
