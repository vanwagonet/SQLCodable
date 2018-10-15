import Foundation
import SQLite3

public enum SQLValue: Equatable {
    case blob(Data)
    case int(Int64)
    case real(Double)
    case text(String)
}

public class SQLDatabase {
    public let fileURL: URL
    private var db: OpaquePointer? = nil

    public init(at url: URL) {
        self.fileURL = url
    }

    func check(_ status: Int32) throws {
        guard status != SQLITE_OK else { return }
        throw SQLError.sqliteError(status, String(cString: sqlite3_errmsg(db)))
    }

    func connect() throws {
        guard db == nil else { return }
        try check(sqlite3_open(fileURL.absoluteString.cString(using: .utf8), &db))
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

    @discardableResult
    func query(_ sql: String, callback: (([String: SQLValue]) -> Void)? = nil) throws -> [[String: SQLValue]] {
        try connect()
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        try check(sqlite3_prepare_v2(db, sql, -1, &statement, nil))
        var rows = [[String: SQLValue]]()
        var isDone = false
        while !isDone {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                var row = [String: SQLValue]()
                for i in 0..<sqlite3_column_count(statement) {
                    let name = String(cString: sqlite3_column_name(statement, i))
                    switch sqlite3_column_type(statement, i) {
                    case SQLITE_BLOB:
                        guard let bytes = sqlite3_column_blob(statement, i) else { break }
                        let count = sqlite3_column_bytes(statement, i)
                        row[name] = .blob(Data(bytes: bytes, count: Int(count)))
                    case SQLITE_INTEGER:
                        row[name] = .int(Int64(sqlite3_column_int(statement, i)))
                    case SQLITE_FLOAT:
                        row[name] = .real(Double(sqlite3_column_double(statement, i)))
                    case SQLITE_TEXT, SQLITE3_TEXT:
                        row[name] = .text(String(cString: sqlite3_column_text(statement, i)))
                    default:
                        break
                    }
                }
                rows.append(row)
                callback?(row)
            case SQLITE_DONE:
                isDone = true
            case let status:
                throw SQLError.sqliteError(status, String(cString: sqlite3_errmsg(db)))
            }
        }
        return rows
    }

    public func create(table: SQLTable) throws {
        let columns = table.columns
            .compactMap { "\($0.name) \($0.type.rawValue) \($0.optional ? "NULL" : "NOT NULL")" }
            .sorted().joined(separator: ", ")
        try exec("CREATE TABLE \(table.name) (\(columns), PRIMARY KEY (\(table.primaryKey.name)))")
    }
}
