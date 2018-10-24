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

    @discardableResult
    func exec(_ sql: String, params: [SQLParameter] = []) throws -> Int32 {
        let _ = try query([String: String].self, sql: sql, params: params)
        return sqlite3_changes(db)
    }

    func query<T: Decodable>(_ type: T.Type, sql: String, params: [SQLParameter] = []) throws -> [T] {
        try connect()
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        try check(sqlite3_prepare_v2(db, sql, -1, &statement, nil))
        for (i, param) in params.enumerated() {
            try check(param.bind(to: statement, index: Int32(i + 1)))
        }
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
            return "\(id(name)) \(col.type.rawValue) \(col.null ? "NULL" : "NOT NULL")"
        }.sorted()
        if !table.primaryKey.isEmpty {
            definitions.append("PRIMARY KEY (\(table.primaryKey.map(id).joined(separator: ", ")))")
        }
        try exec("CREATE TABLE \(id(table.name)) (\(definitions.joined(separator: ", ")))")

        for index in table.indexes {
            try exec("CREATE\(index.unique ? " UNIQUE" : "") INDEX \(id(index.name)) ON \(id(table.name)) (\(index.columns.map(id).joined(separator: ", ")))")
        }
    }

    public func table<Model: SQLCodable>(for type: Model.Type) throws -> SQLTable? {
        let columnInfo = try query(SQLColumnInfo.self, sql: "PRAGMA table_info(\(id(type.tableName)))")
        guard !columnInfo.isEmpty else { return nil }
        var columns = [String: SQLColumn]()
        for info in columnInfo {
            columns[info.name] = SQLColumn(type: info.type, null: !info.notnull)
        }
        let primaryKey = columnInfo.filter { $0.pk > 0 } .sorted(by: { $0.pk < $1.pk }) .map { $0.name }

        let indexInfo = try query(SQLIndexInfo.self, sql: "PRAGMA index_list(\(id(type.tableName)))")
        var indexes = [SQLIndex]()
        for info in indexInfo {
            guard info.origin == "c" else { continue }
            let cols = try query(SQLIndexColumnInfo.self, sql: "PRAGMA index_info(\(id(info.name)))")
            let columns = cols.sorted(by: { $0.seqno < $1.seqno }).map { $0.name }
            indexes.append(SQLIndex(columns: columns, name: info.name, unique: info.unique))
        }

        return SQLTable(columns: columns, indexes: indexes, name: type.tableName, primaryKey: primaryKey)
    }

    public func insert<Model: SQLCodable>(_ model: Model) throws -> Int32 {
        let (columns, values) = try SQLRowEncoder().encode(model)
        let cols = columns.map(id).joined(separator: ", ")
        let vals = columns.map({ _ in "?" }).joined(separator: ", ")
        return try exec("INSERT INTO \(id(Model.tableName)) (\(cols)) VALUES (\(vals))", params: values)
    }

    public func select<Model: SQLCodable>(_ type: Model.Type, where predicate: SQLWhere? = nil, order: [SQLOrder] = [], limit: UInt64 = 0, offset: UInt64 = 0) throws -> [Model] {
        var sql = "SELECT * FROM \(id(Model.tableName))"
        if let clause = predicate?.clause() {
            sql += " WHERE \(clause)"
        }
        if !order.isEmpty {
            sql += " ORDER BY \(order.map { $0.clause() } .joined(separator: ", "))"
        }
        if limit > 0 {
            sql += " LIMIT \(limit)"
            if offset > 0 { sql += " OFFSET \(offset)" }
        }
        return try query(type, sql: sql, params: predicate?.params() ?? [])
    }

    public func delete<Model: SQLCodable>(_ type: Model.Type, where predicate: SQLWhere? = nil) throws -> Int32 {
        var sql = "DELETE FROM \(id(Model.tableName))"
        if let clause = predicate?.clause() {
            sql += " WHERE \(clause)"
        }
        return try exec(sql, params: predicate?.params() ?? [])
    }

    public func delete<Model: SQLCodable>(_ model: Model) throws -> Int32 {
        guard !Model.primaryKey.isEmpty else {
            throw SQLError.noPrimaryKey(Model.self)
        }
        let (columns, values) = try SQLRowEncoder().encode(model)
        return try delete(Model.self, where: .and(Model.primaryKey.map { key in
            if let i = columns.firstIndex(of: key.stringValue) {
                return SQLWhere.is(key, .equalTo, values[i])
            }
            return SQLWhere.null(key)
        }))
    }
}
