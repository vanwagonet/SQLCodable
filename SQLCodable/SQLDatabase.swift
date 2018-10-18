import Foundation
import SQLite3

public class SQLDatabase {
    public let fileURL: URL
    internal var db: OpaquePointer? = nil

    public init(at url: URL) {
        self.fileURL = url
    }

    func check(_ status: Int32) throws {
        guard status != SQLITE_OK else { return }
        throw SQLError.sqliteError(status, String(cString: sqlite3_errmsg(db)))
    }

    func connect() throws {
        guard db == nil else { return }
        let file = fileURL.absoluteString.cString(using: .utf8)
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        try check(sqlite3_open_v2(file, &db, flags, nil))
    }

    func disconnect() throws {
        guard db != nil else { return }
        try check(sqlite3_close(db))
        db = nil
    }

    func exec(_ sql: String) throws {
        try connect()
        try check(sqlite3_exec(db, sql, nil, nil, nil))
    }

    func query<T: Decodable>(_ type: T.Type, sql: String) throws -> [T] {
        try connect()
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        try check(sqlite3_prepare_v2(db, sql, -1, &statement, nil))
        var rows = [T]()
        var isDone = false
        while !isDone {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                rows.append(try SQLRowDecoder(statement: statement).decode(T.self))
            case SQLITE_DONE:
                isDone = true
            case let status:
                throw SQLError.sqliteError(status, String(cString: sqlite3_errmsg(db)))
            }
        }
        return rows
    }

    public func create(table: SQLTable) throws {
        var definitions = table.columns.map { name, col in
            return "\(name) \(col.type.rawValue) \(col.null ? "NULL" : "NOT NULL")"
        }.sorted()
        if !table.primaryKey.isEmpty {
            definitions.append("PRIMARY KEY (\(table.primaryKey.joined(separator: ", ")))")
        }
        try exec("CREATE TABLE \(table.name) (\(definitions.joined(separator: ", ")))")

        for index in table.indexes {
            try exec("CREATE\(index.unique ? " UNIQUE" : "") INDEX \(index.name) ON \(table.name) (\(index.columns.joined(separator: ", ")))")
        }
    }

    public func table<Model: SQLCodable>(for type: Model.Type) throws -> SQLTable? {
        let columnInfo = try query(SQLColumnInfo.self, sql: "PRAGMA table_info(\(type.tableName))")
        guard !columnInfo.isEmpty else { return nil }
        var columns = [String: SQLColumn]()
        for info in columnInfo {
            columns[info.name] = SQLColumn(type: info.type, null: !info.notnull)
        }
        let primaryKey = columnInfo.filter { $0.pk > 0 } .sorted(by: { $0.pk < $1.pk }) .map { $0.name }

        let indexInfo = try query(SQLIndexInfo.self, sql: "PRAGMA index_list(\(type.tableName))")
        var indexes = [SQLIndex]()
        for info in indexInfo {
            guard info.origin == "c" else { continue }
            let cols = try query(SQLIndexColumnInfo.self, sql: "PRAGMA index_info(\(info.name))")
            let columns = cols.sorted(by: { $0.rank < $1.rank }).map { $0.name }
            indexes.append(SQLIndex(columns: columns, name: info.name, unique: info.unique))
        }

        return SQLTable(columns: columns, indexes: indexes, name: type.tableName, primaryKey: primaryKey)
    }
}
