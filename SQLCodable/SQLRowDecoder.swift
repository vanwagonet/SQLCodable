import Foundation
import SQLite3

class SQLRowDecoder: Decoder {
    let codingPath: [CodingKey]
    var indices = [String: Int32]()
    let parent: SQLRowDecoder?
    var rootReturned = false
    let statement: OpaquePointer?
    var userInfo: [CodingUserInfoKey : Any] = [:]

    init(codingPath: [CodingKey] = [], parent: SQLRowDecoder? = nil, statement: OpaquePointer?) {
        self.codingPath = codingPath
        self.parent = parent
        self.statement = statement
    }

    func decode<Model: Decodable>(_ type: Model.Type) throws -> Model {
        for i in 0..<sqlite3_column_count(statement) {
            indices[String(cString: sqlite3_column_name(statement, i))] = i
        }
        return try Model(from: self)
    }

    func string(_ key: CodingKey) -> String {
        guard let i = indices[key.stringValue] else { return "" }
        return String(cString: sqlite3_column_text(statement, i))
    }

    func double(_ key: CodingKey) -> Double {
        guard let i = indices[key.stringValue] else { return 0 }
        return sqlite3_column_double(statement, i)
    }

    func int(_ key: CodingKey) -> Int64 {
        guard let i = indices[key.stringValue] else { return 0 }
        return sqlite3_column_int64(statement, i)
    }

    func blob(_ key: CodingKey) -> Data {
        guard let i = indices[key.stringValue], let bytes = sqlite3_column_blob(statement, i) else {
            return Data()
        }
        let count = Int(sqlite3_column_bytes(statement, i))
        return Data(bytes: bytes, count: count)
    }

    func null(_ key: CodingKey) -> Bool {
        guard let i = indices[key.stringValue] else { return true }
        return sqlite3_column_type(statement, i) == SQLITE_NULL
    }

    func json<T: Decodable>(_ key: CodingKey) throws -> T {
        let json = JSONDecoder()
        return try json.decode(T.self, from: blob(key))
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        if codingPath.isEmpty, !rootReturned {
            rootReturned = true
            let container = SQLRowKeyedDecodingContainer<Key>(decoder: self)
            return KeyedDecodingContainer(container)
        } else if codingPath.isEmpty {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Only one keyed container supported per codingPath"))
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Nested containers are not supported"))
        }
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Unkeyed containers are not supported"))
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        if codingPath.isEmpty {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Single value containers are not supported at the top level"))
        }
        return SQLRowSingleValueDecodingContainer(decoder: self)
    }
}

class SQLRowKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let decoder: SQLRowDecoder
    let codingPath: [CodingKey]
    let allKeys: [Key]

    init(decoder: SQLRowDecoder) {
        self.decoder = decoder
        self.codingPath = decoder.codingPath
        self.allKeys = decoder.indices.keys.compactMap { Key(stringValue: $0) }
    }

    func contains(_ key: Key) -> Bool { return decoder.indices[key.stringValue] != nil }

    func decodeNil(forKey key: Key) throws -> Bool { return decoder.null(key) }

    func decode(_ type: String.Type, forKey key: Key) throws -> String { return decoder.string(key) }
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { return decoder.double(key) }
    func decode(_ type: Float.Type,  forKey key: Key) throws -> Float  { return Float(decoder.double(key)) }
    func decode(_ type: Bool.Type,   forKey key: Key) throws -> Bool   { return decoder.int(key) != 0 }
    func decode(_ type: Int.Type,    forKey key: Key) throws -> Int    { return Int(decoder.int(key)) }
    func decode(_ type: Int8.Type,   forKey key: Key) throws -> Int8   { return Int8(decoder.int(key)) }
    func decode(_ type: Int16.Type,  forKey key: Key) throws -> Int16  { return Int16(decoder.int(key)) }
    func decode(_ type: Int32.Type,  forKey key: Key) throws -> Int32  { return Int32(decoder.int(key)) }
    func decode(_ type: Int64.Type,  forKey key: Key) throws -> Int64  { return decoder.int(key) }
    func decode(_ type: UInt.Type,   forKey key: Key) throws -> UInt   { return UInt(decoder.int(key)) }
    func decode(_ type: UInt8.Type,  forKey key: Key) throws -> UInt8  { return UInt8(decoder.int(key)) }
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { return UInt16(decoder.int(key)) }
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { return UInt32(decoder.int(key)) }
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { return UInt64(decoder.int(key)) }

    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        let child = SQLRowDecoder(codingPath: codingPath + [key], parent: decoder, statement: decoder.statement)
        if let value = try? T(from: child) { return value }
        return try decoder.json(key)
    }

    func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Nested containers are not supported"))
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Nested unkeyed containers are not supported"))
    }

    func superDecoder() throws -> Decoder {
        return decoder
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        return decoder
    }
}

class SQLRowSingleValueDecodingContainer: SingleValueDecodingContainer {
    let decoder: SQLRowDecoder
    let codingPath: [CodingKey]

    init(decoder: SQLRowDecoder) {
        self.decoder = decoder.parent ?? decoder
        self.codingPath = decoder.codingPath
    }

    func key() throws -> CodingKey {
        guard let name = codingPath.last else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Decoding a single value without a codingPath is not supported"))
        }
        return name
    }

    func decodeNil() -> Bool {
        guard let k = try? key() else { return true }
        return decoder.null(k)
    }

    func decode(_ type: String.Type) throws -> String { return decoder.string(try key()) }
    func decode(_ type: Double.Type) throws -> Double { return decoder.double(try key()) }
    func decode(_ type: Float.Type)  throws -> Float  { return Float(decoder.double(try key())) }
    func decode(_ type: Bool.Type)   throws -> Bool   { return decoder.int(try key()) != 0 }
    func decode(_ type: Int.Type)    throws -> Int    { return Int(decoder.int(try key())) }
    func decode(_ type: Int8.Type)   throws -> Int8   { return Int8(decoder.int(try key())) }
    func decode(_ type: Int16.Type)  throws -> Int16  { return Int16(decoder.int(try key())) }
    func decode(_ type: Int32.Type)  throws -> Int32  { return Int32(decoder.int(try key())) }
    func decode(_ type: Int64.Type)  throws -> Int64  { return decoder.int(try key()) }
    func decode(_ type: UInt.Type)   throws -> UInt   { return UInt(decoder.int(try key())) }
    func decode(_ type: UInt8.Type)  throws -> UInt8  { return UInt8(decoder.int(try key())) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { return UInt16(decoder.int(try key())) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { return UInt32(decoder.int(try key())) }
    func decode(_ type: UInt64.Type) throws -> UInt64 { return UInt64(decoder.int(try key())) }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        return try decoder.json(try key())
    }
}
