import Foundation

class SQLTableDecoder: Decoder {
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey : Any] = [:]
    var columns: [SQLColumn] = []
    var rootReturned = false

    init(codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
    }

    func decode<Model: Decodable>(_ type: Model.Type) throws -> [SQLColumn] {
        let _ = try Model(from: self)
        return columns
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        if codingPath.isEmpty, !rootReturned {
            rootReturned = true
            let container = SQLTableKeyedDecodingContainer<Key>(decoder: self)
            return KeyedDecodingContainer(container)
        } else if codingPath.isEmpty {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Only one keyed container supported per codingPath"))
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Nested keyed containers are not supported yet"))
        }
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Unkeyed containers are not supported at the top level"))
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        if codingPath.isEmpty {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Single value containers are not supported at the top level"))
        }
        return SQLTableSingleValueDecodingContainer(decoder: self)
    }
}

class SQLTableKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let decoder: SQLTableDecoder
    let codingPath: [CodingKey]
    let allKeys: [Key] = []
    var optional = Set<String>()

    init(decoder: SQLTableDecoder) {
        self.decoder = decoder
        self.codingPath = decoder.codingPath
    }

    func add(_ type: SQLColumnType, _ key: Key) {
        let name = key.stringValue
        decoder.columns.append(SQLColumn(name: name, optional: optional.contains(name), type: type))
    }

    func contains(_ key: Key) -> Bool { return true }

    func decodeNil(forKey key: Key) throws -> Bool {
        optional.insert(key.stringValue)
        return false // ensures it also asks for the typed value
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String { add(.text, key); return "String" }
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { add(.real, key); return 1.2 }
    func decode(_ type: Float.Type,  forKey key: Key) throws -> Float  { add(.real, key); return 1.1 }
    func decode(_ type: Bool.Type,   forKey key: Key) throws -> Bool   { add(.int,  key); return true }
    func decode(_ type: Int.Type,    forKey key: Key) throws -> Int    { add(.int,  key); return 1 }
    func decode(_ type: Int8.Type,   forKey key: Key) throws -> Int8   { add(.int,  key); return 1 }
    func decode(_ type: Int16.Type,  forKey key: Key) throws -> Int16  { add(.int,  key); return 1 }
    func decode(_ type: Int32.Type,  forKey key: Key) throws -> Int32  { add(.int,  key); return 1 }
    func decode(_ type: Int64.Type,  forKey key: Key) throws -> Int64  { add(.int,  key); return 1 }
    func decode(_ type: UInt.Type,   forKey key: Key) throws -> UInt   { add(.int,  key); return 1 }
    func decode(_ type: UInt8.Type,  forKey key: Key) throws -> UInt8  { add(.int,  key); return 1 }
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { add(.int,  key); return 1 }
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { add(.int,  key); return 1 }
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { add(.int,  key); return 1 }

    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        let child = SQLTableDecoder(codingPath: codingPath + [key])
        let tried = try? T(from: child)
        decoder.columns.append(contentsOf: child.columns)
        if let value = tried { return value }
        if let value = SQLColumn.placeholder(for: T.self) { return value }
        return try T(from: child) // let it throw
    }

    func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Nested containers are not supported"))
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Nested unkeyed containers are not supported"))
    }

    func superDecoder() throws -> Decoder {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Super decoding is not supported"))
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Super decoding is not supported"))
    }
}

class SQLTableSingleValueDecodingContainer: SingleValueDecodingContainer {
    let decoder: SQLTableDecoder
    let codingPath: [CodingKey]
    var optional = false

    init(decoder: SQLTableDecoder) {
        self.decoder = decoder
        self.codingPath = decoder.codingPath
    }

    func add(_ type: SQLColumnType) throws {
        guard let name = codingPath.last?.stringValue else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Decoding a single value without a codingPath is not supported"))
        }
        decoder.columns.append(SQLColumn(name: name, optional: optional, type: type))
    }

    func decodeNil() -> Bool {
        optional = true
        return false // ensures it also asks for the typed value
    }

    func decode(_ type: String.Type) throws -> String { try add(.text); return "String" }
    func decode(_ type: Double.Type) throws -> Double { try add(.real); return 1.2 }
    func decode(_ type: Float.Type)  throws -> Float  { try add(.real); return 1.1 }
    func decode(_ type: Bool.Type)   throws -> Bool   { try add(.int);  return true }
    func decode(_ type: Int.Type)    throws -> Int    { try add(.int);  return 1 }
    func decode(_ type: Int8.Type)   throws -> Int8   { try add(.int);  return 1 }
    func decode(_ type: Int16.Type)  throws -> Int16  { try add(.int);  return 1 }
    func decode(_ type: Int32.Type)  throws -> Int32  { try add(.int);  return 1 }
    func decode(_ type: Int64.Type)  throws -> Int64  { try add(.int);  return 1 }
    func decode(_ type: UInt.Type)   throws -> UInt   { try add(.int);  return 1 }
    func decode(_ type: UInt8.Type)  throws -> UInt8  { try add(.int);  return 1 }
    func decode(_ type: UInt16.Type) throws -> UInt16 { try add(.int);  return 1 }
    func decode(_ type: UInt32.Type) throws -> UInt32 { try add(.int);  return 1 }
    func decode(_ type: UInt64.Type) throws -> UInt64 { try add(.int);  return 1 }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        let child = SQLTableDecoder(codingPath: codingPath)
        let value = try T(from: child)
        decoder.columns.append(contentsOf: child.columns)
        return value
    }
}
