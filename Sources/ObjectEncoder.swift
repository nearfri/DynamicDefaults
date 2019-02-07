
import Foundation

// ref.: https://github.com/apple/swift/blob/master/stdlib/public/Darwin/Foundation/PlistEncoder.swift

public class ObjectEncoder: Encoder {
    public private(set) var codingPath: [CodingKey]
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    public var nilEncodingStrategy: NilEncodingStrategy = .default
    public var passthroughTypes: [Encodable.Type] = [Data.self, Date.self]
    private let storage: Storage = Storage()
    
    public init() {
        self.codingPath = []
    }
    
    private init(codingPath: [CodingKey]) {
        self.codingPath = codingPath
    }
    
    public func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        if canEncodeNewValue {
            storage.pushContainer(DictionaryContainer())
        }
        
        guard let topContainer = storage.topContainer as? DictionaryContainer else {
            preconditionFailure("Attempt to push new keyed encoding container "
                + "when already previously encoded at this path.")
        }
        
        let keyedContainer = KeyedObjectEncodingContainer<Key>(
            referencing: self, codingPath: codingPath, container: topContainer)
        
        return KeyedEncodingContainer(keyedContainer)
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        if canEncodeNewValue {
            storage.pushContainer(ArrayContainer())
        }
        
        guard let topContainer = storage.topContainer as? ArrayContainer else {
            preconditionFailure("Attempt to push new unkeyed encoding container "
                + "when already previously encoded at this path.")
        }
        
        return UnkeyedObjectEncodingContanier(
            referencing: self, codingPath: codingPath, container: topContainer)
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        return SingleValueObjectEncodingContanier(referencing: self, codingPath: codingPath)
    }
    
    private var canEncodeNewValue: Bool {
        return storage.count == codingPath.count
    }
}

extension ObjectEncoder {
    public func encode<T: Encodable>(_ value: T) throws -> Any {
        defer { cleanup() }
        return try box(value)
    }
    
    // 아래와 같은 type-erased value 대신 위와 같은 concreate value를 제공하는 건 의도된 디자인이다.
    // 당장은 타입이 필요없더라도 언젠가는 디코딩을 해야만 할 수도 있고 그러기 위해선 다시 타입이 필요하기 때문이다.
    // 따라서 인코딩을 할 때 타입을 지우는 건 지양해야 한다.
    // https://forums.swift.org/t/how-to-encode-objects-of-unknown-type/12253/9
    private func encodeValue(_ value: Encodable) throws -> Any {
        defer { cleanup() }
        
        if isPassthroughType(type(of: value)) {
            return value
        }
        return try boxValue(value)
    }
    
    private func cleanup() {
        codingPath.removeAll()
        storage.removeAll()
    }
    
    private func box<T: Encodable>(_ value: T) throws -> Any {
        if isPassthroughType(T.self) {
            return value
        }
        return try boxValue(value)
    }
    
    private func isPassthroughType(_ type: Encodable.Type) -> Bool {
        return passthroughTypes.contains(where: { type == $0 })
    }
    
    private func boxValue(_ value: Encodable) throws -> Any {
        let depth = storage.count
        do {
            try value.encode(to: self)
        } catch {
            if storage.count > depth {
                _ = storage.popContainer()
            }
            throw error
        }
        
        guard storage.count > depth else {
            return [:] as [String: Any]
        }
        return storage.popContainer().object
    }
}

// MARK: -

private protocol ObjectContainer {
    var object: Any { get }
}

extension ObjectEncoder {
    private class DictionaryContainer: ObjectContainer {
        private var dictionary: [String: Any] = [:]
        var object: Any { return dictionary }
        
        func set<Key: CodingKey>(_ value: Any, for key: Key) {
            dictionary[key.stringValue] = value
        }
    }
    
    private class ArrayContainer: ObjectContainer {
        private var array: [Any] = []
        var object: Any { return array }
        
        var count: Int {
            return array.count
        }
        
        func append(_ value: Any) {
            array.append(value)
        }
        
        func replace(at index: Int, with value: Any) {
            array[index] = value
        }
    }
    
    private class AnyContainer: ObjectContainer {
        private(set) var object: Any
        
        init(object: Any) {
            self.object = object
        }
    }
    
    private class Storage {
        private(set) var containers: [ObjectContainer] = []
        
        var count: Int {
            return containers.count
        }
        
        var topContainer: ObjectContainer {
            guard let result = containers.last else {
                preconditionFailure("Empty container stack.")
            }
            return result
        }
        
        func pushContainer(_ container: ObjectContainer) {
            containers.append(container)
        }
        
        func popContainer() -> ObjectContainer {
            guard let result = containers.popLast() else {
                preconditionFailure("Empty container stack.")
            }
            return result
        }
        
        func removeAll() {
            containers.removeAll()
        }
    }
}

// MARK: -

extension ObjectEncoder {
    private class ReferencingEncoder: ObjectEncoder {
        private let referenceCodingPath: [CodingKey]
        private let completion: (_ encodedObject: Any) -> Void
        
        init(referenceCodingPath: [CodingKey], key: CodingKey,
             completion: @escaping (_ encodedObject: Any) -> Void) {
            
            self.referenceCodingPath = referenceCodingPath
            self.completion = completion
            super.init(codingPath: referenceCodingPath + [key])
        }
        
        deinit {
            let encodedObject: Any
            switch storage.count {
            case 0: encodedObject = [:] as [String: Any]
            case 1: encodedObject = storage.popContainer().object
            default:
                preconditionFailure(
                    "Referencing encoder deallocated with multiple containers on stack.")
            }
            
            completion(encodedObject)
        }
        
        override var canEncodeNewValue: Bool {
            return storage.count == codingPath.count - referenceCodingPath.count - 1
        }
    }
}

// MARK: -

extension ObjectEncoder {
    private class KeyedObjectEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        private let encoder: ObjectEncoder
        private let container: DictionaryContainer
        private let completion: (_ object: Any) -> Void
        
        let codingPath: [CodingKey]
        
        init(referencing encoder: ObjectEncoder,
             codingPath: [CodingKey], container: DictionaryContainer,
             completion: @escaping (_ object: Any) -> Void = { _ in }) {
            
            self.encoder = encoder
            self.container = container
            self.completion = completion
            self.codingPath = codingPath
        }
        
        deinit {
            completion(container.object)
        }
        
        func encode(_ value: Bool, forKey key: Key) throws { container.set(value, for: key) }
        func encode(_ value: Int, forKey key: Key) throws { container.set(value, for: key) }
        func encode(_ value: Int8, forKey key: Key) throws { container.set(value, for: key) }
        func encode(_ value: Int16, forKey key: Key) throws { container.set(value, for: key) }
        func encode(_ value: Int32, forKey key: Key) throws { container.set(value, for: key) }
        func encode(_ value: Int64, forKey key: Key) throws { container.set(value, for: key) }
        func encode(_ value: UInt, forKey key: Key) throws { container.set(value, for: key) }
        func encode(_ value: UInt8, forKey key: Key) throws { container.set(value, for: key) }
        func encode(_ value: UInt16, forKey key: Key) throws { container.set(value, for: key) }
        func encode(_ value: UInt32, forKey key: Key) throws { container.set(value, for: key) }
        func encode(_ value: UInt64, forKey key: Key) throws { container.set(value, for: key) }
        func encode(_ value: Float, forKey key: Key) throws { container.set(value, for: key) }
        func encode(_ value: Double, forKey key: Key) throws { container.set(value, for: key) }
        func encode(_ value: String, forKey key: Key) throws { container.set(value, for: key) }
        func encodeNil(forKey key: Key) throws {
            container.set(encoder.nilEncodingStrategy.nilValue, for: key)
        }
        
        func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            encoder.codingPath.append(key)
            defer { encoder.codingPath.removeLast() }
            container.set(try encoder.box(value), for: key)
        }
        
        func nestedContainer<NestedKey: CodingKey>(
            keyedBy keyType: NestedKey.Type,
            forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            
            let keyedContainer = KeyedObjectEncodingContainer<NestedKey>(
                referencing: encoder,
                codingPath: codingPath + [key],
                container: DictionaryContainer(),
                completion: { [container] in container.set($0, for: key) })
            return KeyedEncodingContainer(keyedContainer)
        }
        
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            return UnkeyedObjectEncodingContanier(
                referencing: encoder,
                codingPath: codingPath + [key],
                container: ArrayContainer(),
                completion: { [container] in container.set($0, for: key) })
        }
        
        func superEncoder() -> Encoder {
            let key = ObjectKey.superKey
            return ReferencingEncoder(
                referenceCodingPath: encoder.codingPath, key: key,
                completion: { [container] in container.set($0, for: key) })
        }
        
        func superEncoder(forKey key: Key) -> Encoder {
            return ReferencingEncoder(
                referenceCodingPath: encoder.codingPath, key: key,
                completion: { [container] in container.set($0, for: key) })
        }
    }
}

// MARK: -

extension ObjectEncoder {
    private class UnkeyedObjectEncodingContanier: UnkeyedEncodingContainer {
        private let encoder: ObjectEncoder
        private let container: ArrayContainer
        private let completion: (_ object: Any) -> Void
        
        let codingPath: [CodingKey]
        var count: Int {
            return container.count
        }
        
        init(referencing encoder: ObjectEncoder,
             codingPath: [CodingKey], container: ArrayContainer,
             completion: @escaping (_ object: Any) -> Void = { _ in }) {
            
            self.encoder = encoder
            self.container = container
            self.completion = completion
            self.codingPath = codingPath
        }
        
        deinit {
            completion(container.object)
        }
        
        func encode(_ value: Bool) throws { container.append(value) }
        func encode(_ value: Int) throws { container.append(value) }
        func encode(_ value: Int8) throws { container.append(value) }
        func encode(_ value: Int16) throws { container.append(value) }
        func encode(_ value: Int32) throws { container.append(value) }
        func encode(_ value: Int64) throws { container.append(value) }
        func encode(_ value: UInt) throws { container.append(value) }
        func encode(_ value: UInt8) throws { container.append(value) }
        func encode(_ value: UInt16) throws { container.append(value) }
        func encode(_ value: UInt32) throws { container.append(value) }
        func encode(_ value: UInt64) throws { container.append(value) }
        func encode(_ value: Float) throws { container.append(value) }
        func encode(_ value: Double) throws { container.append(value) }
        func encode(_ value: String) throws { container.append(value) }
        func encodeNil() throws { container.append(encoder.nilEncodingStrategy.nilValue) }
        
        func encode<T: Encodable>(_ value: T) throws {
            encoder.codingPath.append(ObjectKey(index: count))
            defer { encoder.codingPath.removeLast() }
            container.append(try encoder.box(value))
        }
        
        func nestedContainer<NestedKey: CodingKey>(
            keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
            
            let index = count
            container.append([:] as [String: Any])
            
            let keyedContainer = KeyedObjectEncodingContainer<NestedKey>(
                referencing: encoder,
                codingPath: codingPath + [ObjectKey(index: index)],
                container: DictionaryContainer(),
                completion: { [container] in container.replace(at: index, with: $0) })
            return KeyedEncodingContainer(keyedContainer)
        }
        
        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            let index = count
            container.append([] as [Any])
            
            return UnkeyedObjectEncodingContanier(
                referencing: encoder,
                codingPath: codingPath + [ObjectKey(index: index)],
                container: ArrayContainer(),
                completion: { [container] in container.replace(at: index, with: $0) })
        }
        
        func superEncoder() -> Encoder {
            let index = count
            container.append("placeholder for superEncoder")
            
            return ReferencingEncoder(
                referenceCodingPath: encoder.codingPath, key: ObjectKey(index: index),
                completion: { [container] in container.replace(at: index, with: $0) })
        }
    }
}

// MARK: -

extension ObjectEncoder {
    private class SingleValueObjectEncodingContanier: SingleValueEncodingContainer {
        private let encoder: ObjectEncoder
        
        let codingPath: [CodingKey]
        
        init(referencing encoder: ObjectEncoder, codingPath: [CodingKey]) {
            self.encoder = encoder
            self.codingPath = codingPath
        }
        
        private func assertCanEncodeNewValue(file: StaticString = #file, line: UInt = #line) {
            precondition(encoder.canEncodeNewValue, """
                Attempt to encode value through single value container \
                when previously value already encoded.
                """, file: file, line: line)
        }
        
        private func pushContainer(
            with value: Any, file: StaticString = #file, line: UInt = #line) {
            
            assertCanEncodeNewValue(file: file, line: line)
            encoder.storage.pushContainer(AnyContainer(object: value))
        }
        
        func encode(_ value: Bool) throws { pushContainer(with: value) }
        func encode(_ value: Int) throws { pushContainer(with: value) }
        func encode(_ value: Int8) throws { pushContainer(with: value) }
        func encode(_ value: Int16) throws { pushContainer(with: value) }
        func encode(_ value: Int32) throws { pushContainer(with: value) }
        func encode(_ value: Int64) throws { pushContainer(with: value) }
        func encode(_ value: UInt) throws { pushContainer(with: value) }
        func encode(_ value: UInt8) throws { pushContainer(with: value) }
        func encode(_ value: UInt16) throws { pushContainer(with: value) }
        func encode(_ value: UInt32) throws { pushContainer(with: value) }
        func encode(_ value: UInt64) throws { pushContainer(with: value) }
        func encode(_ value: Float) throws { pushContainer(with: value) }
        func encode(_ value: Double) throws { pushContainer(with: value) }
        func encode(_ value: String) throws { pushContainer(with: value) }
        func encodeNil() throws { pushContainer(with: encoder.nilEncodingStrategy.nilValue) }
        func encode<T: Encodable>(_ value: T) throws {
            pushContainer(with: try encoder.box(value))
        }
    }
}



