import Foundation

class SQLTableDecoder: Decoder {
    let codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any] = [:]

    var columns = [String: SQLColumn]()
    var nulls = Set<String>()
    let root: SQLTableDecoder?

    init(root: SQLTableDecoder? = nil, codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
        self.root = root
    }

    func decode<Model: Decodable>(_ type: Model.Type) throws -> [String: SQLColumn] {
        let _ = try Model(from: self)
        return columns
    }

    func add(_ type: SQLColumnType, _ name: CodingKey) {
        columns[name.stringValue] = SQLColumn(type: type, null: nulls.contains(name.stringValue))
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        if let root = root, codingPath.count == 1, let name = codingPath.last {
            root.add(.text, name)
        }
        let container = SQLTableKeyedDecodingContainer<Key>(root: root ?? self, codingPath: codingPath)
        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard !codingPath.isEmpty else {
            throw SQLError.notRepresentable("An unkeyed container can't be represented as a row.")
        }
        if let root = root, codingPath.count == 1, let name = codingPath.last {
            root.add(.text, name)
        }
        return SQLTableUnkeyedDecodingContainer(root: root ?? self, codingPath: codingPath)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        guard !codingPath.isEmpty else {
            throw SQLError.notRepresentable("A single value can't be represented as a row.")
        }
        return SQLTableSingleValueDecodingContainer(root: root ?? self, codingPath: codingPath)
    }
}

class SQLTableKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let allKeys: [Key] = []
    let codingPath: [CodingKey]

    let root: SQLTableDecoder

    init(root: SQLTableDecoder, codingPath: [CodingKey]) {
        self.codingPath = codingPath
        self.root = root
    }

    func add(_ type: SQLColumnType, _ name: CodingKey) {
        guard codingPath.isEmpty else { return }
        root.add(type, name)
    }

    func contains(_ key: Key) -> Bool { return true }

    func decodeNil(forKey key: Key) throws -> Bool {
        root.nulls.insert(key.stringValue)
        return false // ensures it also asks for the typed value
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String { add(.text, key); return "" }
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { add(.real, key); return 1 }
    func decode(_ type: Float.Type,  forKey key: Key) throws -> Float  { add(.real, key); return 1 }
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
        let child = SQLTableDecoder(root: root, codingPath: codingPath + [key])
        do {
            return try T(from: child)
        } catch DecodingError.dataCorrupted(_) {
            if let value = SQLTable.placeholder(for: T.self) { return value }
            throw SQLError.missingPlaceholder(type)
        }
    }

    func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        add(.text, key)
        let container = SQLTableKeyedDecodingContainer<NestedKey>(root: root, codingPath: codingPath + [key])
        return KeyedDecodingContainer(container)
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        add(.text, key)
        return SQLTableUnkeyedDecodingContainer(root: root, codingPath: codingPath + [key])
    }

    func superDecoder() throws -> Decoder {
        return root
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        return root
    }
}

class SQLTableUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    let codingPath: [CodingKey]
    let count: Int? = 0
    let currentIndex: Int = 0
    let isAtEnd = true

    let root: SQLTableDecoder

    init(root: SQLTableDecoder, codingPath: [CodingKey]) {
        self.codingPath = codingPath
        self.root = root
    }

    func decodeNil() throws -> Bool { return true }
    func decode(_ type: String.Type) throws -> String { return "" }
    func decode(_ type: Double.Type) throws -> Double { return 1 }
    func decode(_ type: Float.Type)  throws -> Float  { return 1 }
    func decode(_ type: Bool.Type)   throws -> Bool   { return true }
    func decode(_ type: Int.Type)    throws -> Int    { return 1 }
    func decode(_ type: Int8.Type)   throws -> Int8   { return 1 }
    func decode(_ type: Int16.Type)  throws -> Int16  { return 1 }
    func decode(_ type: Int32.Type)  throws -> Int32  { return 1 }
    func decode(_ type: Int64.Type)  throws -> Int64  { return 1 }
    func decode(_ type: UInt.Type)   throws -> UInt   { return 1 }
    func decode(_ type: UInt8.Type)  throws -> UInt8  { return 1 }
    func decode(_ type: UInt16.Type) throws -> UInt16 { return 1 }
    func decode(_ type: UInt32.Type) throws -> UInt32 { return 1 }
    func decode(_ type: UInt64.Type) throws -> UInt64 { return 1 }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        let child = SQLTableDecoder(root: root, codingPath: codingPath)
        do {
            return try T(from: child)
        } catch DecodingError.dataCorrupted(_) {
            if let value = SQLTable.placeholder(for: T.self) { return value }
            throw SQLError.missingPlaceholder(type)
        }
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = SQLTableKeyedDecodingContainer<NestedKey>(root: root, codingPath: codingPath)
        return KeyedDecodingContainer(container)
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        return SQLTableUnkeyedDecodingContainer(root: root, codingPath: codingPath)
    }

    func superDecoder() throws -> Decoder {
        return root
    }
}

class SQLTableSingleValueDecodingContainer: SingleValueDecodingContainer {
    let codingPath: [CodingKey]

    let root: SQLTableDecoder

    init(root: SQLTableDecoder, codingPath: [CodingKey]) {
        self.codingPath = codingPath
        self.root = root
    }

    func add(_ type: SQLColumnType) {
        guard codingPath.count == 1, let name = codingPath.last else { return }
        root.add(type, name)
    }

    func decodeNil() -> Bool {
        return false // ensures it also asks for the typed value
    }

    func decode(_ type: String.Type) throws -> String { add(.text); return "" }
    func decode(_ type: Double.Type) throws -> Double { add(.real); return 1 }
    func decode(_ type: Float.Type)  throws -> Float  { add(.real); return 1 }
    func decode(_ type: Bool.Type)   throws -> Bool   { add(.int);  return true }
    func decode(_ type: Int.Type)    throws -> Int    { add(.int);  return 1 }
    func decode(_ type: Int8.Type)   throws -> Int8   { add(.int);  return 1 }
    func decode(_ type: Int16.Type)  throws -> Int16  { add(.int);  return 1 }
    func decode(_ type: Int32.Type)  throws -> Int32  { add(.int);  return 1 }
    func decode(_ type: Int64.Type)  throws -> Int64  { add(.int);  return 1 }
    func decode(_ type: UInt.Type)   throws -> UInt   { add(.int);  return 1 }
    func decode(_ type: UInt8.Type)  throws -> UInt8  { add(.int);  return 1 }
    func decode(_ type: UInt16.Type) throws -> UInt16 { add(.int);  return 1 }
    func decode(_ type: UInt32.Type) throws -> UInt32 { add(.int);  return 1 }
    func decode(_ type: UInt64.Type) throws -> UInt64 { add(.int);  return 1 }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        let child = SQLTableDecoder(root: root, codingPath: codingPath)
        do {
            return try T(from: child)
        } catch DecodingError.dataCorrupted(_) {
            if let value = SQLTable.placeholder(for: T.self) { return value }
            throw SQLError.missingPlaceholder(type)
        }
    }
}
