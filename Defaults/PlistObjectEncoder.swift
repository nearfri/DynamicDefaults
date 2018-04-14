
import Foundation

// ref.: https://github.com/apple/swift/blob/master/stdlib/public/SDK/Foundation/PlistEncoder.swift

public class PlistObjectEncoder: Encoder {
    public private(set) var codingPath: [CodingKey]
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    public var nilSymbol: String = Constant.defaultNilSymbol
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
        
        let keyedContainer = PlistKeyedEncodingContainer<Key>(
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
        
        return PlistUnkeyedEncodingContanier(
            referencing: self, codingPath: codingPath, container: topContainer)
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        return PlistSingleValueEncodingContanier(referencing: self, codingPath: codingPath)
    }
    
    private var canEncodeNewValue: Bool {
        return storage.count == codingPath.count
    }
}

extension PlistObjectEncoder {
    public func encode<T: Encodable>(_ value: T) throws -> Any {
        defer { cleanup() }
        return try box(value)
    }
    
    private func cleanup() {
        codingPath.removeAll()
        storage.removeAll()
    }
    
    private func box<T: Encodable>(_ value: T) throws -> Any {
        if T.self == Data.self || T.self == Date.self || T.self == URL.self {
            return value
        }
        
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

extension PlistObjectEncoder {
    internal enum Constant {
        static let defaultNilSymbol = "$null"
    }
}

// MARK: -

private protocol PlistObjectContainer {
    var object: Any { get }
}

extension PlistObjectEncoder {
    private class DictionaryContainer: PlistObjectContainer {
        private var dictionary: [String: Any] = [:]
        var object: Any { return dictionary }
        
        func set<Key: CodingKey>(_ value: Any, for key: Key) {
            dictionary[key.stringValue] = value
        }
    }
    
    private class ArrayContainer: PlistObjectContainer {
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
    
    private class AnyContainer: PlistObjectContainer {
        var object: Any
        
        init(object: Any) {
            self.object = object
        }
    }
    
    private class Storage {
        private(set) var containers: [PlistObjectContainer] = []
        
        var count: Int {
            return containers.count
        }
        
        var topContainer: PlistObjectContainer {
            guard let result = containers.last else {
                preconditionFailure("Empty container stack.")
            }
            return result
        }
        
        func pushContainer(_ container: PlistObjectContainer) {
            containers.append(container)
        }
        
        func popContainer() -> PlistObjectContainer {
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

extension PlistObjectEncoder {
    private class ReferencingEncoder: PlistObjectEncoder {
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

extension PlistObjectEncoder {
    private class PlistKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        private let encoder: PlistObjectEncoder
        private let container: DictionaryContainer
        private let completion: (_ object: Any) -> Void
        
        let codingPath: [CodingKey]
        
        init(referencing encoder: PlistObjectEncoder,
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
        func encodeNil(forKey key: Key) throws { container.set(encoder.nilSymbol, for: key) }
        
        func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            encoder.codingPath.append(key)
            defer { encoder.codingPath.removeLast() }
            container.set(try encoder.box(value), for: key)
        }
        
        func nestedContainer<NestedKey: CodingKey>(
            keyedBy keyType: NestedKey.Type,
            forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            
            let keyedContainer = PlistKeyedEncodingContainer<NestedKey>(
                referencing: encoder,
                codingPath: codingPath + [key],
                container: DictionaryContainer(),
                completion: { [container] in container.set($0, for: key) })
            return KeyedEncodingContainer(keyedContainer)
        }
        
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            return PlistUnkeyedEncodingContanier(
                referencing: encoder,
                codingPath: codingPath + [key],
                container: ArrayContainer(),
                completion: { [container] in container.set($0, for: key) })
        }
        
        func superEncoder() -> Encoder {
            let key = PlistObjectKey.superKey
            return ReferencingEncoder(
                referenceCodingPath: codingPath, key: key,
                completion: { [container] in container.set($0, for: key) })
        }
        
        func superEncoder(forKey key: Key) -> Encoder {
            return ReferencingEncoder(
                referenceCodingPath: codingPath, key: key,
                completion: { [container] in container.set($0, for: key) })
        }
    }
}

// MARK: -

extension PlistObjectEncoder {
    private class PlistUnkeyedEncodingContanier: UnkeyedEncodingContainer {
        private let encoder: PlistObjectEncoder
        private let container: ArrayContainer
        private let completion: (_ object: Any) -> Void
        
        let codingPath: [CodingKey]
        var count: Int {
            return container.count
        }
        
        init(referencing encoder: PlistObjectEncoder,
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
        
        func encode(_ value: Bool) throws { container.append(value)}
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
        func encodeNil() throws { container.append(encoder.nilSymbol) }
        
        func encode<T: Encodable>(_ value: T) throws {
            encoder.codingPath.append(PlistObjectKey(index: count))
            defer { encoder.codingPath.removeLast() }
            container.append(try encoder.box(value))
        }
        
        func nestedContainer<NestedKey: CodingKey>(
            keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
            
            let index = count
            container.append([:] as [String: Any])
            
            let keyedContainer = PlistKeyedEncodingContainer<NestedKey>(
                referencing: encoder,
                codingPath: codingPath + [PlistObjectKey(index: index)],
                container: DictionaryContainer(),
                completion: { [container] in container.replace(at: index, with: $0) })
            return KeyedEncodingContainer(keyedContainer)
        }
        
        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            let index = count
            container.append([] as [Any])
            
            return PlistUnkeyedEncodingContanier(
                referencing: encoder,
                codingPath: codingPath + [PlistObjectKey(index: index)],
                container: ArrayContainer(),
                completion: { [container] in container.replace(at: index, with: $0) })
        }
        
        func superEncoder() -> Encoder {
            let index = count
            container.append("placeholder for superEncoder")
            
            return ReferencingEncoder(
                referenceCodingPath: codingPath, key: PlistObjectKey(index: index),
                completion: { [container] in container.replace(at: index, with: $0) })
        }
    }
}

// MARK: -

extension PlistObjectEncoder {
    private class PlistSingleValueEncodingContanier: SingleValueEncodingContainer {
        private let encoder: PlistObjectEncoder
        
        let codingPath: [CodingKey]
        
        init(referencing encoder: PlistObjectEncoder, codingPath: [CodingKey]) {
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
        func encodeNil() throws { pushContainer(with: encoder.nilSymbol) }
        func encode<T: Encodable>(_ value: T) throws {
            pushContainer(with: try encoder.box(value))
        }
    }
}



