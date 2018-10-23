import Foundation

public struct SQLIndex: Equatable, Hashable {
    public let columns: [String]
    public let name: String
    public let unique: Bool

    internal init(columns: [String], name: String, unique: Bool) {
        self.columns = columns
        self.name = name
        self.unique = unique
    }

    public init(_ name: String, on columns: [CodingKey], unique: Bool = false) {
        self.init(columns: columns.map { $0.stringValue } .sorted(), name: name, unique: unique)
    }
}

// PRAGMA index_list
struct SQLIndexInfo: Decodable {
    let name: String
    let origin: String
    let unique: Bool
}

// PRAGMA index_info
struct SQLIndexColumnInfo: Decodable {
    let name: String
    let seqno: Int32
}
