
import Foundation

// ref.: https://github.com/apple/swift/blob/master/stdlib/public/SDK/Foundation/PlistEncoder.swift

public class PlistObjectEncoder: Encoder {
    public private(set) var codingPath: [CodingKey]
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    private var storage: Storage = Storage()
    
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
    public convenience init() {
        self.init(codingPath: [])
    }
    
    public func encode<T: Encodable>(_ value: T) throws -> Any {
        return try box(value)
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

private protocol PlistObjectContainer {
    var object: Any { get }
}

extension PlistObjectEncoder {
    private class DictionaryContainer: PlistObjectContainer {
        var dictionary: [String: Any] = [:]
        var object: Any { return dictionary }
    }
    
    private class ArrayContainer: PlistObjectContainer {
        var array: [Any] = []
        var object: Any { return array }
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
    }
}

extension PlistObjectEncoder {
    private class ReferencingEncoder: PlistObjectEncoder {
        private let referenceCodingPath: [CodingKey]
        private let completion: (_ encodedObject: Any) -> Void
        
        init(referencing encoder: PlistObjectEncoder, at index: Int,
             completion: @escaping (_ encodedObject: Any) -> Void) {
            
            self.referenceCodingPath = encoder.codingPath
            self.completion = completion
            let codingPath = encoder.codingPath + [PlistObjectKey(index: index)]
            super.init(codingPath: codingPath)
        }
        
        init(referencing encoder: PlistObjectEncoder, at key: CodingKey,
             completion: @escaping (_ encodedObject: Any) -> Void) {
            
            self.referenceCodingPath = encoder.codingPath
            self.completion = completion
            let codingPath = encoder.codingPath + [key]
            super.init(codingPath: codingPath)
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

extension PlistObjectEncoder {
    private class PlistKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        private let encoder: PlistObjectEncoder
        private let container: DictionaryContainer
        private let completion: (_ encodedObject: [String: Any]) -> Void
        
        let codingPath: [CodingKey]
        
        init(referencing encoder: PlistObjectEncoder,
             codingPath: [CodingKey], container: DictionaryContainer,
             completion: @escaping (_ encodedObject: [String: Any]) -> Void = { _ in }) {
            
            self.encoder = encoder
            self.container = container
            self.completion = completion
            self.codingPath = codingPath
        }
        
        deinit {
            completion(container.dictionary)
        }
        
        func encode(_ value: Bool, forKey key: Key) throws {
            container.dictionary[key.stringValue] = value
        }
        func encode(_ value: Int, forKey key: Key) throws {
            container.dictionary[key.stringValue] = value
        }
        func encode(_ value: Int8, forKey key: Key) throws {
            container.dictionary[key.stringValue] = value
        }
        func encode(_ value: Int16, forKey key: Key) throws {
            container.dictionary[key.stringValue] = value
        }
        func encode(_ value: Int32, forKey key: Key) throws {
            container.dictionary[key.stringValue] = value
        }
        func encode(_ value: Int64, forKey key: Key) throws {
            container.dictionary[key.stringValue] = value
        }
        func encode(_ value: UInt, forKey key: Key) throws {
            container.dictionary[key.stringValue] = value
        }
        func encode(_ value: UInt8, forKey key: Key) throws {
            container.dictionary[key.stringValue] = value
        }
        func encode(_ value: UInt16, forKey key: Key) throws {
            container.dictionary[key.stringValue] = value
        }
        func encode(_ value: UInt32, forKey key: Key) throws {
            container.dictionary[key.stringValue] = value
        }
        func encode(_ value: UInt64, forKey key: Key) throws {
            container.dictionary[key.stringValue] = value
        }
        func encode(_ value: Float, forKey key: Key) throws {
            container.dictionary[key.stringValue] = value
        }
        func encode(_ value: Double, forKey key: Key) throws {
            container.dictionary[key.stringValue] = value
        }
        func encode(_ value: String, forKey key: Key) throws {
            container.dictionary[key.stringValue] = value
        }
        func encodeNil(forKey key: Key) throws {
            container.dictionary[key.stringValue] = Constant.nullValue
        }
        
        func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            encoder.codingPath.append(key)
            defer { encoder.codingPath.removeLast() }
            container.dictionary[key.stringValue] = try encoder.box(value)
        }
        
        func nestedContainer<NestedKey: CodingKey>(
            keyedBy keyType: NestedKey.Type,
            forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            
            let keyedContainer = PlistKeyedEncodingContainer<NestedKey>(
                referencing: encoder,
                codingPath: codingPath + [key],
                container: DictionaryContainer(),
                completion: { [container] in container.dictionary[key.stringValue] = $0 })
            return KeyedEncodingContainer(keyedContainer)
        }
        
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            return PlistUnkeyedEncodingContanier(
                referencing: encoder,
                codingPath: codingPath + [key],
                container: ArrayContainer(),
                completion: { [container] in container.dictionary[key.stringValue] = $0 })
        }
        
        func superEncoder() -> Encoder {
            let key = PlistObjectKey.superKey
            return ReferencingEncoder(
                referencing: encoder, at: key,
                completion: { [container] in container.dictionary[key.stringValue] = $0 })
        }
        
        func superEncoder(forKey key: Key) -> Encoder {
            return ReferencingEncoder(
                referencing: encoder, at: key,
                completion: { [container] in container.dictionary[key.stringValue] = $0 })
        }
    }
}

extension PlistObjectEncoder {
    private class PlistUnkeyedEncodingContanier: UnkeyedEncodingContainer {
        private let encoder: PlistObjectEncoder
        private let container: ArrayContainer
        private let completion: (_ encodedObject: [Any]) -> Void
        
        let codingPath: [CodingKey]
        var count: Int {
            return container.array.count
        }
        
        init(referencing encoder: PlistObjectEncoder,
             codingPath: [CodingKey], container: ArrayContainer,
             completion: @escaping (_ encodedObject: [Any]) -> Void = { _ in }) {
            
            self.encoder = encoder
            self.container = container
            self.completion = completion
            self.codingPath = codingPath
        }
        
        deinit {
            completion(container.array)
        }
        
        func encode(_ value: Bool) throws { container.array.append(value)}
        func encode(_ value: Int) throws { container.array.append(value) }
        func encode(_ value: Int8) throws { container.array.append(value) }
        func encode(_ value: Int16) throws { container.array.append(value) }
        func encode(_ value: Int32) throws { container.array.append(value) }
        func encode(_ value: Int64) throws { container.array.append(value) }
        func encode(_ value: UInt) throws { container.array.append(value) }
        func encode(_ value: UInt8) throws { container.array.append(value) }
        func encode(_ value: UInt16) throws { container.array.append(value) }
        func encode(_ value: UInt32) throws { container.array.append(value) }
        func encode(_ value: UInt64) throws { container.array.append(value) }
        func encode(_ value: Float) throws { container.array.append(value) }
        func encode(_ value: Double) throws { container.array.append(value) }
        func encode(_ value: String) throws { container.array.append(value) }
        func encodeNil() throws { container.array.append(Constant.nullValue) }
        
        func encode<T: Encodable>(_ value: T) throws {
            encoder.codingPath.append(PlistObjectKey(index: count))
            defer { encoder.codingPath.removeLast() }
            container.array.append(try encoder.box(value))
        }
        
        func nestedContainer<NestedKey: CodingKey>(
            keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
            
            let index = count
            container.array.append([:] as [String: Any])
            
            let keyedContainer = PlistKeyedEncodingContainer<NestedKey>(
                referencing: encoder,
                codingPath: codingPath + [PlistObjectKey(index: index)],
                container: DictionaryContainer(),
                completion: { [container] in container.array[index] = $0 })
            return KeyedEncodingContainer(keyedContainer)
        }
        
        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            let index = count
            container.array.append([] as [Any])
            
            return PlistUnkeyedEncodingContanier(
                referencing: encoder,
                codingPath: codingPath + [PlistObjectKey(index: index)],
                container: ArrayContainer(),
                completion: { [container] in container.array[index] = $0 })
        }
        
        func superEncoder() -> Encoder {
            let index = count
            container.array.append("placeholder for superEncoder")
            
            return ReferencingEncoder(
                referencing: encoder, at: index,
                completion: { [container] in container.array[index] = $0 })
        }
    }
    
    private class PlistSingleValueEncodingContanier: SingleValueEncodingContainer {
        private let encoder: PlistObjectEncoder
        
        let codingPath: [CodingKey]
        
        init(referencing encoder: PlistObjectEncoder, codingPath: [CodingKey]) {
            self.encoder = encoder
            self.codingPath = codingPath
        }
        
        private func assertCanEncodeNewValue() {
            precondition(encoder.canEncodeNewValue, """
                Attempt to encode value through single value container \
                when previously value already encoded.
                """)
        }
        
        func encode(_ value: Bool) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(AnyContainer(object: value))
        }
        
        func encode(_ value: Int) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(AnyContainer(object: value))
        }
        
        func encode(_ value: Int8) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(AnyContainer(object: value))
        }
        
        func encode(_ value: Int16) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(AnyContainer(object: value))
        }
        
        func encode(_ value: Int32) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(AnyContainer(object: value))
        }
        
        func encode(_ value: Int64) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(AnyContainer(object: value))
        }
        
        func encode(_ value: UInt) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(AnyContainer(object: value))
        }
        
        func encode(_ value: UInt8) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(AnyContainer(object: value))
        }
        
        func encode(_ value: UInt16) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(AnyContainer(object: value))
        }
        
        func encode(_ value: UInt32) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(AnyContainer(object: value))
        }
        
        func encode(_ value: UInt64) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(AnyContainer(object: value))
        }
        
        func encode(_ value: Float) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(AnyContainer(object: value))
        }
        
        func encode(_ value: Double) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(AnyContainer(object: value))
        }
        
        func encode(_ value: String) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(AnyContainer(object: value))
        }
        
        func encodeNil() throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(AnyContainer(object: Constant.nullValue))
        }
        
        func encode<T: Encodable>(_ value: T) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(AnyContainer(object: try encoder.box(value)))
        }
    }
}

extension PlistObjectEncoder {
    internal enum Constant {
        static let nullValue = "$null"
    }
}



