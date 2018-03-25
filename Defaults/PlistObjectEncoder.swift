
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
        precondition(canEncodeNewValue, """
            Attempt to push new keyed encoding container \
            when already previously encoded at this path.
            """)
        
        storage.pushContainer([:] as [String: Any])
        let index = storage.count - 1
        
        let keyedContainer = KeyedContainer<Key>(
            referencing: self,
            codingPath: codingPath,
            completion: { self.storage.replaceContainer(at: index, with: $0) })
        return KeyedEncodingContainer(keyedContainer)
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        precondition(canEncodeNewValue, """
            Attempt to push new unkeyed encoding container \
            when already previously encoded at this path.
            """)
        
        storage.pushContainer([] as [Any])
        let index = storage.count - 1
        
        return UnkeyedContanier(
            referencing: self,
            codingPath: codingPath,
            completion: { self.storage.replaceContainer(at: index, with: $0) })
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        return SingleValueContanier(referencing: self, codingPath: codingPath)
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
        return storage.popContainer()
    }
}

extension PlistObjectEncoder {
    private class Storage {
        private(set) var containers: [Any] = []
        
        var count: Int {
            return containers.count
        }
        
        func pushContainer(_ container: Any) {
            containers.append(container)
        }
        
        func popContainer() -> Any {
            guard let result = containers.popLast() else {
                preconditionFailure("Empty container stack.")
            }
            return result
        }
        
        func replaceContainer(at index: Int, with container: Any) {
            precondition(index < count, "Invalid container index.")
            let oldType = type(of: containers[index])
            let newType = type(of: container)
            precondition(oldType == newType,
                         "Attempt to replace container \(oldType) with \(newType)")
            
            containers[index] = container
        }
    }
}

extension PlistObjectEncoder {
    private class ReferencingEncoder: PlistObjectEncoder {
        private let referenceCodingPath: [CodingKey]
        private let completion: (_ value: Any) -> Void
        
        init(referencing encoder: PlistObjectEncoder, at index: Int,
             completion: @escaping (_ value: Any) -> Void = { _ in }) {
            
            self.referenceCodingPath = encoder.codingPath
            self.completion = completion
            let codingPath = encoder.codingPath + [PlistObjectKey(index: index)]
            super.init(codingPath: codingPath)
        }
        
        init(referencing encoder: PlistObjectEncoder, at key: CodingKey,
             completion: @escaping (_ value: Any) -> Void = { _ in }) {
            
            self.referenceCodingPath = encoder.codingPath
            self.completion = completion
            let codingPath = encoder.codingPath + [key]
            super.init(codingPath: codingPath)
        }
        
        deinit {
            let value: Any
            switch storage.count {
            case 0: value = [:] as [String: Any]
            case 1: value = storage.popContainer()
            default:
                preconditionFailure(
                    "Referencing encoder deallocated with multiple containers on stack.")
            }
            
            completion(value)
        }
        
        override var canEncodeNewValue: Bool {
            return storage.count == codingPath.count - referenceCodingPath.count - 1
        }
    }
}

extension PlistObjectEncoder {
    private class KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        private let encoder: PlistObjectEncoder
        private let completion: (_ container: [String: Any]) -> Void
        private var container: [String: Any] = [:]
        
        let codingPath: [CodingKey]
        
        init(referencing encoder: PlistObjectEncoder, codingPath: [CodingKey],
             completion: @escaping (_ container: [String: Any]) -> Void) {
            
            self.encoder = encoder
            self.completion = completion
            self.codingPath = codingPath
        }
        
        deinit {
            completion(container)
        }
        
        func encode(_ value: Bool, forKey key: Key) throws { container[key.stringValue] = value }
        func encode(_ value: Int, forKey key: Key) throws { container[key.stringValue] = value }
        func encode(_ value: Int8, forKey key: Key) throws { container[key.stringValue] = value }
        func encode(_ value: Int16, forKey key: Key) throws { container[key.stringValue] = value }
        func encode(_ value: Int32, forKey key: Key) throws { container[key.stringValue] = value }
        func encode(_ value: Int64, forKey key: Key) throws { container[key.stringValue] = value }
        func encode(_ value: UInt, forKey key: Key) throws { container[key.stringValue] = value }
        func encode(_ value: UInt8, forKey key: Key) throws { container[key.stringValue] = value }
        func encode(_ value: UInt16, forKey key: Key) throws { container[key.stringValue] = value }
        func encode(_ value: UInt32, forKey key: Key) throws { container[key.stringValue] = value }
        func encode(_ value: UInt64, forKey key: Key) throws { container[key.stringValue] = value }
        func encode(_ value: Float, forKey key: Key) throws { container[key.stringValue] = value }
        func encode(_ value: Double, forKey key: Key) throws { container[key.stringValue] = value }
        func encode(_ value: String, forKey key: Key) throws { container[key.stringValue] = value }
        func encodeNil(forKey key: Key) throws { container[key.stringValue] = Constant.nullValue }
        
        func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            let valueEncoder = ReferencingEncoder(referencing: encoder, at: key)
            container[key.stringValue] = try valueEncoder.box(value)
        }
        
        func nestedContainer<NestedKey: CodingKey>(
            keyedBy keyType: NestedKey.Type,
            forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            
            let keyedContainer = KeyedContainer<NestedKey>(
                referencing: encoder,
                codingPath: codingPath + [key],
                completion: { self.container[key.stringValue] = $0 })
            return KeyedEncodingContainer(keyedContainer)
        }
        
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            return UnkeyedContanier(
                referencing: encoder,
                codingPath: codingPath + [key],
                completion: { self.container[key.stringValue] = $0 })
        }
        
        func superEncoder() -> Encoder {
            let key = PlistObjectKey.superKey
            return ReferencingEncoder(
                referencing: encoder, at: key,
                completion: { self.container[key.stringValue] = $0 })
        }
        
        func superEncoder(forKey key: Key) -> Encoder {
            return ReferencingEncoder(
                referencing: encoder, at: key,
                completion: { self.container[key.stringValue] = $0 })
        }
    }
}

extension PlistObjectEncoder {
    private class UnkeyedContanier: UnkeyedEncodingContainer {
        private let encoder: PlistObjectEncoder
        private let completion: (_ container: [Any]) -> Void
        private var container: [Any] = []
        
        let codingPath: [CodingKey]
        var count: Int {
            return container.count
        }
        
        init(referencing encoder: PlistObjectEncoder, codingPath: [CodingKey],
             completion: @escaping (_ container: [Any]) -> Void) {
            
            self.encoder = encoder
            self.completion = completion
            self.codingPath = codingPath
        }
        
        deinit {
            completion(container)
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
        func encodeNil() throws { container.append(Constant.nullValue) }
        
        func encode<T: Encodable>(_ value: T) throws {
            let valueEncoder = ReferencingEncoder(referencing: encoder, at: count)
            container.append(try valueEncoder.box(value))
        }
        
        func nestedContainer<NestedKey: CodingKey>(
            keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
            
            let index = count
            let placeholder = "placeholder for nestedContainer at \(index)"
            container.append(placeholder)
            
            let keyedContainer = KeyedContainer<NestedKey>(
                referencing: encoder,
                codingPath: codingPath + [PlistObjectKey(index: index)],
                completion: { self.container[index] = $0 })
            return KeyedEncodingContainer(keyedContainer)
        }
        
        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            let index = count
            let placeholder = "placeholder for nestedUnkeyedContainer at \(index)"
            container.append(placeholder)
            
            return UnkeyedContanier(
                referencing: encoder,
                codingPath: codingPath + [PlistObjectKey(index: index)],
                completion: { self.container[index] = $0 })
        }
        
        func superEncoder() -> Encoder {
            let index = count
            let placeholder = "placeholder for superEncoder at \(index)"
            container.append(placeholder)
            
            return ReferencingEncoder(
                referencing: encoder, at: index,
                completion: { self.container[index] = $0 })
        }
    }
    
    private class SingleValueContanier: SingleValueEncodingContainer {
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
            encoder.storage.pushContainer(value)
        }
        
        func encode(_ value: Int) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(value)
        }
        
        func encode(_ value: Int8) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(value)
        }
        
        func encode(_ value: Int16) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(value)
        }
        
        func encode(_ value: Int32) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(value)
        }
        
        func encode(_ value: Int64) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(value)
        }
        
        func encode(_ value: UInt) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(value)
        }
        
        func encode(_ value: UInt8) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(value)
        }
        
        func encode(_ value: UInt16) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(value)
        }
        
        func encode(_ value: UInt32) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(value)
        }
        
        func encode(_ value: UInt64) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(value)
        }
        
        func encode(_ value: Float) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(value)
        }
        
        func encode(_ value: Double) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(value)
        }
        
        func encode(_ value: String) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(value)
        }
        
        func encodeNil() throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(Constant.nullValue)
        }
        
        func encode<T: Encodable>(_ value: T) throws {
            assertCanEncodeNewValue()
            encoder.storage.pushContainer(try encoder.box(value))
        }
    }
}

extension PlistObjectEncoder {
    internal enum Constant {
        static let nullValue = "$null"
    }
}



