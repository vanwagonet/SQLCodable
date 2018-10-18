import Foundation

class SQLTableDecoder: Decoder {
    let codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any] = [:]
    var columns = [String: SQLColumn]()
    var nulls = Set<String>()
    let parent: SQLTableDecoder?
    var rootReturned = false

    init(codingPath: [CodingKey] = [], parent: SQLTableDecoder? = nil) {
        self.codingPath = codingPath
        self.parent = parent
    }

    func decode<Model: Decodable>(_ type: Model.Type) throws -> [String: SQLColumn] {
        let _ = try Model(from: self)
        return columns
    }

    func add(_ type: SQLColumnType, _ name: CodingKey) {
        columns[name.stringValue] = SQLColumn(type: type, null: nulls.contains(name.stringValue))
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        if codingPath.isEmpty, !rootReturned {
            rootReturned = true
            let container = SQLTableKeyedDecodingContainer<Key>(decoder: self)
            return KeyedDecodingContainer(container)
        } else if codingPath.isEmpty {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Only one keyed container supported per codingPath"))
        } else {
            if let name = codingPath.last { parent?.add(.text, name) }
            let container = SQLTableNestedDecodingContainer<Key>(decoder: self)
            return KeyedDecodingContainer(container)
        }
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        if codingPath.isEmpty {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Unkeyed containers are not supported at the top level"))
        }
        if let name = codingPath.last { parent?.add(.text, name) }
        return SQLTableUnkeyedDecodingContainer(decoder: self)
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

    init(decoder: SQLTableDecoder) {
        self.decoder = decoder
        self.codingPath = decoder.codingPath
    }

    func add(_ type: SQLColumnType, _ key: Key) {
        decoder.add(type, key)
    }

    func contains(_ key: Key) -> Bool { return true }

    func decodeNil(forKey key: Key) throws -> Bool {
        decoder.nulls.insert(key.stringValue)
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
        let child = SQLTableDecoder(codingPath: codingPath + [key], parent: decoder)
        let tried = try? T(from: child)
        if let value = tried { return value }
        if let value = SQLTable.placeholder(for: T.self) { return value }
        return try T(from: child) // let it throw
    }

    func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        add(.blob, key)
        let container = SQLTableNestedDecodingContainer<NestedKey>(decoder: decoder)
        return KeyedDecodingContainer(container)
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

class SQLTableSingleValueDecodingContainer: SingleValueDecodingContainer {
    let decoder: SQLTableDecoder
    let codingPath: [CodingKey]

    init(decoder: SQLTableDecoder) {
        self.decoder = decoder
        self.codingPath = decoder.codingPath
    }

    func add(_ type: SQLColumnType) throws {
        guard let name = codingPath.last else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Decoding a single value without a codingPath is not supported"))
        }
        decoder.parent?.add(type, name)
    }

    func decodeNil() -> Bool {
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
        let child = SQLTableDecoder(codingPath: codingPath, parent: decoder)
        return try T(from: child)
    }
}

class SQLTableUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    let decoder: SQLTableDecoder
    let codingPath: [CodingKey]
    let count: Int? = 0
    let isAtEnd = true
    let currentIndex: Int = 0

    init(decoder: SQLTableDecoder) {
        self.decoder = decoder
        self.codingPath = decoder.codingPath
    }

    func nope() -> Error {
        return DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Nested values are not supported"))
    }

    func decodeNil() throws -> Bool { return true }
    func decode(_ type: String.Type) throws -> String { throw nope() }
    func decode(_ type: Double.Type) throws -> Double { throw nope() }
    func decode(_ type: Float.Type)  throws -> Float  { throw nope() }
    func decode(_ type: Bool.Type)   throws -> Bool   { throw nope() }
    func decode(_ type: Int.Type)    throws -> Int    { throw nope() }
    func decode(_ type: Int8.Type)   throws -> Int8   { throw nope() }
    func decode(_ type: Int16.Type)  throws -> Int16  { throw nope() }
    func decode(_ type: Int32.Type)  throws -> Int32  { throw nope() }
    func decode(_ type: Int64.Type)  throws -> Int64  { throw nope() }
    func decode(_ type: UInt.Type)   throws -> UInt   { throw nope() }
    func decode(_ type: UInt8.Type)  throws -> UInt8  { throw nope() }
    func decode(_ type: UInt16.Type) throws -> UInt16 { throw nope() }
    func decode(_ type: UInt32.Type) throws -> UInt32 { throw nope() }
    func decode(_ type: UInt64.Type) throws -> UInt64 { throw nope() }
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable { throw nope() }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Nested containers are not supported"))
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Nested unkeyed containers are not supported"))
    }

    func superDecoder() throws -> Decoder {
        return decoder
    }
}

class SQLTableNestedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let decoder: SQLTableDecoder
    let codingPath: [CodingKey]
    let allKeys: [Key] = []

    init(decoder: SQLTableDecoder) {
        self.decoder = decoder
        self.codingPath = decoder.codingPath
    }

    func contains(_ key: Key) -> Bool { return true }

    func decodeNil(forKey key: Key) throws -> Bool { return true }

    func decode(_ type: String.Type, forKey key: Key) throws -> String { return "String" }
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { return 1.2 }
    func decode(_ type: Float.Type,  forKey key: Key) throws -> Float  { return 1.1 }
    func decode(_ type: Bool.Type,   forKey key: Key) throws -> Bool   { return true }
    func decode(_ type: Int.Type,    forKey key: Key) throws -> Int    { return 1 }
    func decode(_ type: Int8.Type,   forKey key: Key) throws -> Int8   { return 1 }
    func decode(_ type: Int16.Type,  forKey key: Key) throws -> Int16  { return 1 }
    func decode(_ type: Int32.Type,  forKey key: Key) throws -> Int32  { return 1 }
    func decode(_ type: Int64.Type,  forKey key: Key) throws -> Int64  { return 1 }
    func decode(_ type: UInt.Type,   forKey key: Key) throws -> UInt   { return 1 }
    func decode(_ type: UInt8.Type,  forKey key: Key) throws -> UInt8  { return 1 }
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { return 1 }
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { return 1 }
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { return 1 }

    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        let child = SQLTableDecoder(codingPath: codingPath + [key], parent: decoder)
        let tried = try? T(from: child)
        if let value = tried { return value }
        if let value = SQLTable.placeholder(for: T.self) { return value }
        return try T(from: child) // let it throw
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = SQLTableNestedDecodingContainer<NestedKey>(decoder: decoder)
        return KeyedDecodingContainer(container)
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        return SQLTableUnkeyedDecodingContainer(decoder: decoder)
    }

    func superDecoder() throws -> Decoder {
        return decoder
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        return decoder
    }
}
