import Foundation

class SQLRowEncoder: Encoder {
    let codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any] = [:]

    let root: SQLRowEncoder?
    var values = [String: SQLParameter]()

    init(root: SQLRowEncoder? = nil, codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
        self.root = root
    }

    func add(_ param: SQLParameter, _ key: CodingKey) {
        values[key.stringValue] = param
    }

    func json<Model: Encodable>(_ value: Model, _ key: CodingKey) throws {
        let json = JSONEncoder()
        json.dateEncodingStrategy = .secondsSince1970
        let data = try json.encode(value)
        add(.value(String(data: data, encoding: .utf8) ?? ""), key)
    }

    func encode<Model: SQLCodable>(_ model: Model) throws -> [String: SQLParameter] {
        for (key, value) in try SQLTable(for: Model.self).columns {
            if value.null { values[key] = .null }
        }
        try model.encode(to: self)
        return values
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        let container = SQLRowKeyedEncodingContainer<Key>(root: root ?? self, codingPath: codingPath)
        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return SQLRowBadUnkeyedEncodingContainer(root: root ?? self, codingPath: codingPath)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        return SQLRowSingleValueEncodingContainer(root: root ?? self, codingPath: codingPath)
    }
}

class SQLRowKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let codingPath: [CodingKey]

    let root: SQLRowEncoder

    init(root: SQLRowEncoder, codingPath: [CodingKey]) {
        self.codingPath = codingPath
        self.root = root
    }

    func encodeNil(forKey key: Key) throws { root.add(.null, key) }

    func encode(_ value: String, forKey key: Key) throws { root.add(.value(value), key) }
    func encode(_ value: Double, forKey key: Key) throws { root.add(.value(value), key) }
    func encode(_ value: Float,  forKey key: Key) throws { root.add(.value(value), key) }
    func encode(_ value: Bool,   forKey key: Key) throws { root.add(.value(value), key) }
    func encode(_ value: Int,    forKey key: Key) throws { root.add(.value(value), key) }
    func encode(_ value: Int8,   forKey key: Key) throws { root.add(.value(value), key) }
    func encode(_ value: Int16,  forKey key: Key) throws { root.add(.value(value), key) }
    func encode(_ value: Int32,  forKey key: Key) throws { root.add(.value(value), key) }
    func encode(_ value: Int64,  forKey key: Key) throws { root.add(.value(value), key) }
    func encode(_ value: UInt,   forKey key: Key) throws { root.add(.value(value), key) }
    func encode(_ value: UInt8,  forKey key: Key) throws { root.add(.value(value), key) }
    func encode(_ value: UInt16, forKey key: Key) throws { root.add(.value(value), key) }
    func encode(_ value: UInt32, forKey key: Key) throws { root.add(.value(value), key) }
    func encode(_ value: UInt64, forKey key: Key) throws { root.add(.value(value), key) }

    func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        let child = SQLRowEncoder(root: root, codingPath: codingPath + [key])
        do {
            try value.encode(to: child)
        } catch {
            try root.json(value, key)
        }
    }

    func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        let container = SQLRowBadEncodingContainer<NestedKey>(root: root, codingPath: codingPath + [key])
        return KeyedEncodingContainer(container)
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        return SQLRowBadUnkeyedEncodingContainer(root: root, codingPath: codingPath + [key])
    }

    func superEncoder() -> Encoder { return root }
    func superEncoder(forKey key: Key) -> Encoder { return root }
}

class SQLRowSingleValueEncodingContainer: SingleValueEncodingContainer {
    let codingPath: [CodingKey]

    let root: SQLRowEncoder

    init(root: SQLRowEncoder, codingPath: [CodingKey]) {
        self.codingPath = codingPath
        self.root = root
    }

    func add(_ param: SQLParameter) throws {
        guard let key = codingPath.last, codingPath.count == 1 else {
            throw SQLError.notRepresentable("A single value can't be represented as a row.")
        }
        root.add(param, key)
    }

    func encodeNil() throws { try add(.null) }

    func encode(_ value: String) throws { try add(.value(value)) }
    func encode(_ value: Double) throws { try add(.value(value)) }
    func encode(_ value: Float)  throws { try add(.value(value)) }
    func encode(_ value: Bool)   throws { try add(.value(value)) }
    func encode(_ value: Int)    throws { try add(.value(value)) }
    func encode(_ value: Int8)   throws { try add(.value(value)) }
    func encode(_ value: Int16)  throws { try add(.value(value)) }
    func encode(_ value: Int32)  throws { try add(.value(value)) }
    func encode(_ value: Int64)  throws { try add(.value(value)) }
    func encode(_ value: UInt)   throws { try add(.value(value)) }
    func encode(_ value: UInt8)  throws { try add(.value(value)) }
    func encode(_ value: UInt16) throws { try add(.value(value)) }
    func encode(_ value: UInt32) throws { try add(.value(value)) }
    func encode(_ value: UInt64) throws { try add(.value(value)) }

    func encode<T: Encodable>(_ value: T) throws {
        guard let key = codingPath.last, codingPath.count == 1 else {
            throw SQLError.notRepresentable("A single value can't be represented as a row.")
        }
        try root.json(value, key)
    }
}

class SQLRowBadEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let codingPath: [CodingKey]
    let count: Int = 0

    let root: SQLRowEncoder

    init(root: SQLRowEncoder, codingPath: [CodingKey]) {
        self.codingPath = codingPath
        self.root = root
    }

    func error() throws {
        throw SQLError.notRepresentable("Nested containers can't be encoded. Use encode<Encodable> instead.")
    }

    func encodeNil(forKey key: Key) throws { try error() }

    func encode(_ value: String, forKey key: Key) throws { try error() }
    func encode(_ value: Double, forKey key: Key) throws { try error() }
    func encode(_ value: Float,  forKey key: Key) throws { try error() }
    func encode(_ value: Bool,   forKey key: Key) throws { try error() }
    func encode(_ value: Int,    forKey key: Key) throws { try error() }
    func encode(_ value: Int8,   forKey key: Key) throws { try error() }
    func encode(_ value: Int16,  forKey key: Key) throws { try error() }
    func encode(_ value: Int32,  forKey key: Key) throws { try error() }
    func encode(_ value: Int64,  forKey key: Key) throws { try error() }
    func encode(_ value: UInt,   forKey key: Key) throws { try error() }
    func encode(_ value: UInt8,  forKey key: Key) throws { try error() }
    func encode(_ value: UInt16, forKey key: Key) throws { try error() }
    func encode(_ value: UInt32, forKey key: Key) throws { try error() }
    func encode(_ value: UInt64, forKey key: Key) throws { try error() }

    func encode<T: Encodable>(_ value: T, forKey key: Key) throws { try error() }

    func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        let container = SQLRowBadEncodingContainer<NestedKey>(root: root, codingPath: codingPath)
        return KeyedEncodingContainer(container)
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        return SQLRowBadUnkeyedEncodingContainer(root: root, codingPath: codingPath + [key])
    }

    func superEncoder() -> Encoder { return root }
    func superEncoder(forKey key: Key) -> Encoder { return root }
}

class SQLRowBadUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    let codingPath: [CodingKey]
    let count: Int = 0

    let root: SQLRowEncoder

    init(root: SQLRowEncoder, codingPath: [CodingKey]) {
        self.codingPath = codingPath
        self.root = root
    }

    func error() throws {
        throw SQLError.notRepresentable("Unkeyed containers can't be encoded. Use encode<Encodable> instead.")
    }

    func encodeNil() throws { try error() }

    func encode(_ value: String) throws { try error() }
    func encode(_ value: Double) throws { try error() }
    func encode(_ value: Float)  throws { try error() }
    func encode(_ value: Bool)   throws { try error() }
    func encode(_ value: Int)    throws { try error() }
    func encode(_ value: Int8)   throws { try error() }
    func encode(_ value: Int16)  throws { try error() }
    func encode(_ value: Int32)  throws { try error() }
    func encode(_ value: Int64)  throws { try error() }
    func encode(_ value: UInt)   throws { try error() }
    func encode(_ value: UInt8)  throws { try error() }
    func encode(_ value: UInt16) throws { try error() }
    func encode(_ value: UInt32) throws { try error() }
    func encode(_ value: UInt64) throws { try error() }

    func encode<T: Encodable>(_ value: T) throws { try error() }

    func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        let container = SQLRowBadEncodingContainer<NestedKey>(root: root, codingPath: codingPath)
        return KeyedEncodingContainer(container)
    }

    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return SQLRowBadUnkeyedEncodingContainer(root: root, codingPath: codingPath)
    }

    func superEncoder() -> Encoder { return root }
}
