import Foundation
import SQLite3

class SQLRowDecoder: Decoder {
    let codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey : Any] = [:]

    var indices = [String: Int32]()
    let root: SQLRowDecoder?
    let statement: OpaquePointer?

    init(root: SQLRowDecoder? = nil, codingPath: [CodingKey] = [], statement: OpaquePointer?) {
        self.codingPath = codingPath
        self.root = root
        self.statement = statement
    }

    func decode<Model: Decodable>(_ type: Model.Type) throws -> Model {
        for i in 0..<sqlite3_column_count(statement) {
            indices[String(cString: sqlite3_column_name(statement, i))] = i
        }
        return try Model(from: self)
    }

    func index(of key: CodingKey) throws -> Int32 {
        if let i = indices[key.stringValue] { return i }
        throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "There is no column \"\(key.stringValue)\" in the result row."))
    }

    func string(_ key: CodingKey) throws -> String {
        return String(cString: sqlite3_column_text(statement, try index(of: key)))
    }

    func double(_ key: CodingKey) throws -> Double {
        return sqlite3_column_double(statement, try index(of: key))
    }

    func int(_ key: CodingKey) throws -> Int64 {
        return sqlite3_column_int64(statement, try index(of: key))
    }

    func blob(_ key: CodingKey) throws -> Data {
        let i = try index(of: key)
        guard let bytes = sqlite3_column_blob(statement, i) else { return Data() }
        let count = Int(sqlite3_column_bytes(statement, i))
        return Data(bytes: bytes, count: count)
    }

    func null(_ key: CodingKey) -> Bool {
        guard let i = indices[key.stringValue] else { return true }
        return sqlite3_column_type(statement, i) == SQLITE_NULL
    }

    func json<T: Decodable>(_ key: CodingKey) throws -> T {
        let json = JSONDecoder()
        json.dateDecodingStrategy = .secondsSince1970
        return try json.decode(T.self, from: blob(key))
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        guard codingPath.isEmpty else {
            throw SQLError.notRepresentable("A nested container can't be decoded. Fall back to JSONEncoder.")
        }
        let container = SQLRowKeyedDecodingContainer<Key>(root: root ?? self, codingPath: codingPath)
        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw SQLError.notRepresentable("An unkeyed container can't be represented as a row.")
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return try SQLRowSingleValueDecodingContainer(root: root ?? self, codingPath: codingPath)
    }
}

class SQLRowKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let allKeys: [Key]
    let codingPath: [CodingKey]

    let root: SQLRowDecoder

    init(root: SQLRowDecoder, codingPath: [CodingKey]) {
        self.allKeys = root.indices.keys.compactMap { Key(stringValue: $0) }
        self.codingPath = codingPath
        self.root = root
    }

    func contains(_ key: Key) -> Bool { return root.indices[key.stringValue] != nil }

    func decodeNil(forKey key: Key) throws -> Bool { return root.null(key) }

    func decode(_ type: String.Type, forKey key: Key) throws -> String { return try root.string(key) }
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { return try root.double(key) }
    func decode(_ type: Float.Type,  forKey key: Key) throws -> Float  { return Float(try root.double(key)) }
    func decode(_ type: Bool.Type,   forKey key: Key) throws -> Bool   { return try root.int(key) != 0 }
    func decode(_ type: Int.Type,    forKey key: Key) throws -> Int    { return Int(try root.int(key)) }
    func decode(_ type: Int8.Type,   forKey key: Key) throws -> Int8   { return Int8(try root.int(key)) }
    func decode(_ type: Int16.Type,  forKey key: Key) throws -> Int16  { return Int16(try root.int(key)) }
    func decode(_ type: Int32.Type,  forKey key: Key) throws -> Int32  { return Int32(try root.int(key)) }
    func decode(_ type: Int64.Type,  forKey key: Key) throws -> Int64  { return try root.int(key) }
    func decode(_ type: UInt.Type,   forKey key: Key) throws -> UInt   { return UInt(try root.int(key)) }
    func decode(_ type: UInt8.Type,  forKey key: Key) throws -> UInt8  { return UInt8(try root.int(key)) }
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { return UInt16(try root.int(key)) }
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { return UInt32(try root.int(key)) }
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { return UInt64(try root.int(key)) }

    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        let child = SQLRowDecoder(root: root, codingPath: codingPath + [key], statement: root.statement)
        if let value = try? T(from: child) { return value }
        return try root.json(key)
    }

    func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        throw SQLError.notRepresentable("A nested container can't be decoded. Use decode<Decodable>() instead.")
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        throw SQLError.notRepresentable("A nested unkeyed container can't be decoded. Use decode<Decodable>() instead.")
    }

    func superDecoder() throws -> Decoder { return root }
    func superDecoder(forKey key: Key) throws -> Decoder { return root }
}

class SQLRowSingleValueDecodingContainer: SingleValueDecodingContainer {
    let codingPath: [CodingKey]

    let key: CodingKey
    let root: SQLRowDecoder

    init(root: SQLRowDecoder, codingPath: [CodingKey]) throws {
        guard let key = codingPath.last, codingPath.count == 1 else {
            throw SQLError.notRepresentable("A single value can't be represented as a row.")
        }
        self.codingPath = codingPath
        self.key = key
        self.root = root
    }

    func decodeNil() -> Bool { return root.null(key) }

    func decode(_ type: String.Type) throws -> String { return try root.string(key) }
    func decode(_ type: Double.Type) throws -> Double { return try root.double(key) }
    func decode(_ type: Float.Type)  throws -> Float  { return Float(try root.double(key)) }
    func decode(_ type: Bool.Type)   throws -> Bool   { return try root.int(key) != 0 }
    func decode(_ type: Int.Type)    throws -> Int    { return Int(try root.int(key)) }
    func decode(_ type: Int8.Type)   throws -> Int8   { return Int8(try root.int(key)) }
    func decode(_ type: Int16.Type)  throws -> Int16  { return Int16(try root.int(key)) }
    func decode(_ type: Int32.Type)  throws -> Int32  { return Int32(try root.int(key)) }
    func decode(_ type: Int64.Type)  throws -> Int64  { return try root.int(key) }
    func decode(_ type: UInt.Type)   throws -> UInt   { return UInt(try root.int(key)) }
    func decode(_ type: UInt8.Type)  throws -> UInt8  { return UInt8(try root.int(key)) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { return UInt16(try root.int(key)) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { return UInt32(try root.int(key)) }
    func decode(_ type: UInt64.Type) throws -> UInt64 { return UInt64(try root.int(key)) }

    func decode<T: Decodable>(_ type: T.Type) throws -> T { return try root.json(key) }
}
