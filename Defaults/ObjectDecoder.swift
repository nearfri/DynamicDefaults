
import Foundation

// ref.: https://github.com/apple/swift/blob/master/stdlib/public/Darwin/Foundation/PlistEncoder.swift

public class ObjectDecoder: Decoder {
    public private(set) var codingPath: [CodingKey]
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    public var nilSymbol: String = ObjectEncoder.Constant.defaultNilSymbol
    private var storage: Storage = Storage()
    
    public init() {
        self.codingPath = []
    }
    
    private init(codingPath: [CodingKey], container: Any) {
        self.codingPath = codingPath
        self.storage.pushContainer(container)
    }
    
    public func container<Key: CodingKey>(
        keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        
        if let string = storage.topContainer as? String, string == nilSymbol {
            let desc = "Cannot get keyed decoding container -- found nil value instead."
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: desc)
            throw DecodingError.valueNotFound(KeyedDecodingContainer<Key>.self, context)
        }
        
        guard let topContainer = storage.topContainer as? [String: Any] else {
            throw Error.typeMismatch(codingPath: codingPath, expectation: [String: Any].self,
                                     reality: storage.topContainer)
        }
        
        let decodingContainer = KeyedObjectDecodingContainer<Key>(
            referencing: self, codingPath: codingPath, container: topContainer)
        return KeyedDecodingContainer(decodingContainer)
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        if let string = storage.topContainer as? String, string == nilSymbol {
            let desc = "Cannot get unkeyed decoding container -- found nil value instead."
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: desc)
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self, context)
        }
        
        guard let topContainer = storage.topContainer as? [Any] else {
            throw Error.typeMismatch(codingPath: codingPath, expectation: [Any].self,
                                     reality: storage.topContainer)
        }
        
        return UnkeyedObjectDecodingContainer(
            referencing: self, codingPath: codingPath, container: topContainer)
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return SingleValueObjectDecodingContainer(referencing: self, codingPath: codingPath)
    }
}

extension ObjectDecoder {
    public func decode<T: Decodable>(_ type: T.Type, from value: Any) throws -> T {
        defer { cleanup() }
        return try unbox(value, as: type)
    }
    
    // ObjectEncoder.encodeValue()와 마찬가지 이유로 type-erased 구현은 공개하지 않는다.
    private func decodeValue(of type: Decodable.Type, from object: Any) throws -> Any {
        defer { cleanup() }
        
        if Swift.type(of: object) == type {
            return object
        }
        
        storage.pushContainer(object)
        defer { storage.popContainer() }
        
        return try type.init(from: self)
    }
    
    private func cleanup() {
        codingPath.removeAll()
        storage.removeAll()
    }
    
    private func unbox<T: Decodable>(_ value: Any, as type: T.Type) throws -> T {
        if let value = value as? T {
            return value
        }
        
        storage.pushContainer(value)
        defer { storage.popContainer() }
        
        return try type.init(from: self)
    }
}

// MARK: -

extension ObjectDecoder {
    private class Storage {
        private(set) var containers: [Any] = []
        
        var count: Int {
            return containers.count
        }
        
        var topContainer: Any {
            guard let result = containers.last else {
                preconditionFailure("Empty container stack.")
            }
            return result
        }
        
        func pushContainer(_ container: Any) {
            containers.append(container)
        }
        
        func popContainer() {
            precondition(!containers.isEmpty, "Empty container stack.")
            containers.removeLast()
        }
        
        func removeAll() {
            containers.removeAll()
        }
    }
}

// MARK: -

extension ObjectDecoder {
    private struct KeyedObjectDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        private let decoder: ObjectDecoder
        private let container: [String: Any]
        
        let codingPath: [CodingKey]
        
        var allKeys: [Key] {
            return container.keys.compactMap { Key(stringValue: $0) }
        }
        
        init(referencing decoder: ObjectDecoder,
             codingPath: [CodingKey], container: [String: Any]) {
            
            self.decoder = decoder
            self.container = container
            self.codingPath = codingPath
        }
        
        func contains(_ key: Key) -> Bool {
            return container[key.stringValue] != nil
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            let value = try self.value(forKey: key)
            if let string = value as? String, string == decoder.nilSymbol {
                return true
            }
            return false
        }
        
        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
            return try decodeValue(type: type, forKey: key)
        }
        
        func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
            return try decodeValue(type: type, forKey: key)
        }
        
        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
            return try decodeValue(type: type, forKey: key)
        }
        
        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
            return try decodeValue(type: type, forKey: key)
        }
        
        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
            return try decodeValue(type: type, forKey: key)
        }
        
        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
            return try decodeValue(type: type, forKey: key)
        }
        
        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
            return try decodeValue(type: type, forKey: key)
        }
        
        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
            return try decodeValue(type: type, forKey: key)
        }
        
        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
            return try decodeValue(type: type, forKey: key)
        }
        
        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
            return try decodeValue(type: type, forKey: key)
        }
        
        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
            return try decodeValue(type: type, forKey: key)
        }
        
        func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
            return try decodeValue(type: type, forKey: key)
        }
        
        func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
            return try decodeValue(type: type, forKey: key)
        }
        
        func decode(_ type: String.Type, forKey key: Key) throws -> String {
            return try decodeValue(type: type, forKey: key)
        }
        
        func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
            let value = try self.value(forKey: key)
            if let string = value as? String, string == decoder.nilSymbol {
                throw Error.valueNotFound(codingPath: decoder.codingPath + [key], expectation: type)
            }
            
            decoder.codingPath.append(key)
            defer { decoder.codingPath.removeLast() }
            
            return try decoder.unbox(value, as: type)
        }
        
        private func value(forKey key: Key) throws -> Any {
            guard let result = container[key.stringValue] else {
                throw Error.keyNotFound(codingPath: decoder.codingPath, key: key)
            }
            return result
        }
        
        private func decodeValue<T: InitializableWithAny>(
            type: T.Type, forKey key: Key) throws -> T {
            
            let value = try self.value(forKey: key)
            if let string = value as? String, string == decoder.nilSymbol {
                throw Error.valueNotFound(codingPath: decoder.codingPath + [key], expectation: type)
            }
            
            return try type.init(value: value, codingPath: decoder.codingPath + [key])
        }
        
        func nestedContainer<NestedKey: CodingKey>(
            keyedBy type: NestedKey.Type,
            forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
            
            let nestedCodingPath = codingPath + [key]
            
            guard let value = container[key.stringValue] else {
                let desc = "Cannot get nested keyed container -- "
                    + "no value found for key \"\(key.stringValue)\"."
                let context = DecodingError.Context(codingPath: nestedCodingPath,
                                                    debugDescription: desc)
                throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self, context)
            }
            
            guard let dictionary = value as? [String: Any] else {
                throw Error.typeMismatch(codingPath: nestedCodingPath,
                                         expectation: [String: Any].self, reality: value)
            }
            
            let keyedContainer = KeyedObjectDecodingContainer<NestedKey>(
                referencing: decoder, codingPath: nestedCodingPath, container: dictionary)
            return KeyedDecodingContainer(keyedContainer)
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            let nestedCodingPath = codingPath + [key]
            
            guard let value = container[key.stringValue] else {
                let desc = "Cannot get nested unkeyed container -- "
                    + "no value found for key \"\(key.stringValue)\"."
                let context = DecodingError.Context(codingPath: nestedCodingPath,
                                                    debugDescription: desc)
                throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self, context)
            }
            
            guard let array = value as? [Any] else {
                throw Error.typeMismatch(codingPath: nestedCodingPath,
                                         expectation: [Any].self, reality: value)
            }
            
            return UnkeyedObjectDecodingContainer(
                referencing: decoder, codingPath: nestedCodingPath, container: array)
        }
        
        func superDecoder() throws -> Decoder {
            return try makeSuperDecoder(key: ObjectKey.superKey)
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            return try makeSuperDecoder(key: key)
        }
        
        private func makeSuperDecoder(key: CodingKey) throws -> Decoder {
            let superCodingPath = codingPath + [key]
            
            guard let value = container[key.stringValue] else {
                let desc = "Cannot get superDecoder() -- "
                    + "no value found for key \"\(key.stringValue)\"."
                let context = DecodingError.Context(codingPath: superCodingPath,
                                                    debugDescription: desc)
                throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self, context)
            }
            return ObjectDecoder(codingPath: superCodingPath, container: value)
        }
    }
}

// MARK: -

extension ObjectDecoder {
    private struct UnkeyedObjectDecodingContainer: UnkeyedDecodingContainer {
        private let decoder: ObjectDecoder
        private let container: [Any]
        
        let codingPath: [CodingKey]
        
        private(set) var currentIndex: Int
        
        var count: Int? {
            return container.count
        }
        
        var isAtEnd: Bool {
            return currentIndex >= count!
        }
        
        init(referencing decoder: ObjectDecoder, codingPath: [CodingKey], container: [Any]) {
            self.decoder = decoder
            self.container = container
            self.codingPath = codingPath
            self.currentIndex = 0
        }
        
        mutating func decodeNil() throws -> Bool {
            guard !isAtEnd else {
                throw makeEndOfContainerError(expectation: Any?.self)
            }
            
            if let string = container[currentIndex] as? String, string == decoder.nilSymbol {
                currentIndex += 1
                return true
            } else {
                return false
            }
        }
        
        mutating func decode(_ type: Bool.Type) throws -> Bool {
            return try decodeValue(type: type)
        }
        
        mutating func decode(_ type: Int.Type) throws -> Int {
            return try decodeValue(type: type)
        }
        
        mutating func decode(_ type: Int8.Type) throws -> Int8 {
            return try decodeValue(type: type)
        }
        
        mutating func decode(_ type: Int16.Type) throws -> Int16 {
            return try decodeValue(type: type)
        }
        
        mutating func decode(_ type: Int32.Type) throws -> Int32 {
            return try decodeValue(type: type)
        }
        
        mutating func decode(_ type: Int64.Type) throws -> Int64 {
            return try decodeValue(type: type)
        }
        
        mutating func decode(_ type: UInt.Type) throws -> UInt {
            return try decodeValue(type: type)
        }
        
        mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
            return try decodeValue(type: type)
        }
        
        mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
            return try decodeValue(type: type)
        }
        
        mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
            return try decodeValue(type: type)
        }
        
        mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
            return try decodeValue(type: type)
        }
        
        mutating func decode(_ type: Float.Type) throws -> Float {
            return try decodeValue(type: type)
        }
        
        mutating func decode(_ type: Double.Type) throws -> Double {
            return try decodeValue(type: type)
        }
        
        mutating func decode(_ type: String.Type) throws -> String {
            return try decodeValue(type: type)
        }
        
        mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
            guard !isAtEnd else {
                throw makeEndOfContainerError(expectation: type)
            }
            
            decoder.codingPath.append(ObjectKey(index: currentIndex))
            defer { decoder.codingPath.removeLast() }
            
            let value = container[currentIndex]
            if let string = value as? String, string == decoder.nilSymbol {
                throw Error.valueNotFound(codingPath: decoder.codingPath, expectation: type)
            }
            
            let decodedValue = try decoder.unbox(value, as: type)
            currentIndex += 1
            
            return decodedValue
        }
        
        private func makeEndOfContainerError(expectation: Any.Type) -> DecodingError {
            let currentCodingPath = decoder.codingPath + [ObjectKey(index: currentIndex)]
            let context = DecodingError.Context(codingPath: currentCodingPath,
                                                debugDescription: "Unkeyed container is at end.")
            return DecodingError.valueNotFound(expectation, context)
        }
        
        private mutating func decodeValue<T: InitializableWithAny>(type: T.Type) throws -> T {
            guard !isAtEnd else {
                throw makeEndOfContainerError(expectation: type)
            }
            
            decoder.codingPath.append(ObjectKey(index: currentIndex))
            defer { decoder.codingPath.removeLast() }
            
            let value = container[currentIndex]
            if let string = value as? String, string == decoder.nilSymbol {
                throw Error.valueNotFound(codingPath: decoder.codingPath, expectation: type)
            }
            
            let decodedValue = try type.init(value: value, codingPath: decoder.codingPath)
            currentIndex += 1
            
            return decodedValue
        }
        
        mutating func nestedContainer<NestedKey: CodingKey >(
            keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
            
            let nestedCodingPath = codingPath + [ObjectKey(index: currentIndex)]
            
            guard !isAtEnd else {
                let desc = "Cannot get nested keyed container -- unkeyed container is at end."
                let context = DecodingError.Context(codingPath: nestedCodingPath,
                                                    debugDescription: desc)
                throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self, context)
            }
            
            let value = container[currentIndex]
            guard let dictionary = value as? [String: Any] else {
                throw Error.typeMismatch(codingPath: nestedCodingPath,
                                         expectation: [String: Any].self, reality: value)
            }
            
            currentIndex += 1
            
            let keyedContainer = KeyedObjectDecodingContainer<NestedKey>(
                referencing: decoder, codingPath: nestedCodingPath, container: dictionary)
            return KeyedDecodingContainer(keyedContainer)
        }
        
        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            let nestedCodingPath = codingPath + [ObjectKey(index: currentIndex)]
            
            guard !isAtEnd else {
                let desc = "Cannot get nested unkeyed container -- unkeyed container is at end."
                let context = DecodingError.Context(codingPath: nestedCodingPath,
                                                    debugDescription: desc)
                throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self, context)
            }
            
            let value = container[currentIndex]
            guard let array = value as? [Any] else {
                throw Error.typeMismatch(codingPath: nestedCodingPath,
                                         expectation: [Any].self, reality: value)
            }
            
            currentIndex += 1
            
            return UnkeyedObjectDecodingContainer(
                referencing: decoder, codingPath: nestedCodingPath, container: array)
        }
        
        mutating func superDecoder() throws -> Decoder {
            let superCodingPath = codingPath + [ObjectKey(index: currentIndex)]
            
            guard !isAtEnd else {
                let desc = "Cannot get superDecoder() -- unkeyed container is at end."
                let context = DecodingError.Context(codingPath: superCodingPath,
                                                    debugDescription: desc)
                throw DecodingError.valueNotFound(Decoder.self, context)
            }
            
            let value = container[currentIndex]
            
            currentIndex += 1
            
            return ObjectDecoder(codingPath: superCodingPath, container: value)
        }
    }
}

// MARK: -

extension ObjectDecoder {
    private struct SingleValueObjectDecodingContainer: SingleValueDecodingContainer {
        private let decoder: ObjectDecoder
        
        let codingPath: [CodingKey]
        
        init(referencing decoder: ObjectDecoder, codingPath: [CodingKey]) {
            self.decoder = decoder
            self.codingPath = codingPath
        }
        
        func decodeNil() -> Bool {
            let value = decoder.storage.topContainer
            if let string = value as? String, string == decoder.nilSymbol {
                return true
            }
            return false
        }
        
        func decode(_ type: Bool.Type) throws -> Bool {
            return try Bool(value: decoder.storage.topContainer, codingPath: decoder.codingPath)
        }
        
        func decode(_ type: Int.Type) throws -> Int {
            return try Int(value: decoder.storage.topContainer, codingPath: decoder.codingPath)
        }
        
        func decode(_ type: Int8.Type) throws -> Int8 {
            return try Int8(value: decoder.storage.topContainer, codingPath: decoder.codingPath)
        }
        
        func decode(_ type: Int16.Type) throws -> Int16 {
            return try Int16(value: decoder.storage.topContainer, codingPath: decoder.codingPath)
        }
        
        func decode(_ type: Int32.Type) throws -> Int32 {
            return try Int32(value: decoder.storage.topContainer, codingPath: decoder.codingPath)
        }
        
        func decode(_ type: Int64.Type) throws -> Int64 {
            return try Int64(value: decoder.storage.topContainer, codingPath: decoder.codingPath)
        }
        
        func decode(_ type: UInt.Type) throws -> UInt {
            return try UInt(value: decoder.storage.topContainer, codingPath: decoder.codingPath)
        }
        
        func decode(_ type: UInt8.Type) throws -> UInt8 {
            return try UInt8(value: decoder.storage.topContainer, codingPath: decoder.codingPath)
        }
        
        func decode(_ type: UInt16.Type) throws -> UInt16 {
            return try UInt16(value: decoder.storage.topContainer, codingPath: decoder.codingPath)
        }
        
        func decode(_ type: UInt32.Type) throws -> UInt32 {
            return try UInt32(value: decoder.storage.topContainer, codingPath: decoder.codingPath)
        }
        
        func decode(_ type: UInt64.Type) throws -> UInt64 {
            return try UInt64(value: decoder.storage.topContainer, codingPath: decoder.codingPath)
        }
        
        func decode(_ type: Float.Type) throws -> Float {
            return try Float(value: decoder.storage.topContainer, codingPath: decoder.codingPath)
        }
        
        func decode(_ type: Double.Type) throws -> Double {
            return try Double(value: decoder.storage.topContainer, codingPath: decoder.codingPath)
        }
        
        func decode(_ type: String.Type) throws -> String {
            return try String(value: decoder.storage.topContainer, codingPath: decoder.codingPath)
        }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            let value = decoder.storage.topContainer
            if let string = value as? String, string == decoder.nilSymbol {
                throw Error.valueNotFound(codingPath: decoder.codingPath, expectation: type)
            }
            
            return try decoder.unbox(value, as: type)
        }
        
        private func decodeValue<T: InitializableWithAny>(type: T.Type) throws -> T {
            let value = decoder.storage.topContainer
            if let string = value as? String, string == decoder.nilSymbol {
                throw Error.valueNotFound(codingPath: decoder.codingPath, expectation: type)
            }
            
            return try type.init(value: value, codingPath: decoder.codingPath)
        }
    }
}

// MARK: -

private enum Error {
    static func keyNotFound(codingPath: [CodingKey], key: CodingKey) -> DecodingError {
        let desc = "No value associated with key \(key) (\"\(key.stringValue)\")."
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: desc)
        return DecodingError.keyNotFound(key, context)
    }
    
    static func valueNotFound(
        codingPath: [CodingKey], expectation: Any.Type) -> DecodingError {
        
        let desc = "Expected \(expectation) value but found nil instead."
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: desc)
        return DecodingError.valueNotFound(expectation, context)
    }
    
    static func typeMismatch(
        codingPath: [CodingKey], expectation: Any.Type, reality: Any) -> DecodingError {
        
        let desc = "Expected to decode \(expectation) but found \(type(of: reality)) instead."
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: desc)
        return DecodingError.typeMismatch(expectation, context)
    }
    
    static func dataCorrupted<T1, T2: Numeric>(
        codingPath: [CodingKey], expectation: T1.Type, reality: T2) -> DecodingError {
        
        let desc = "Parsed number <\(reality)> does not fit in \(expectation)."
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: desc)
        return DecodingError.dataCorrupted(context)
    }
}

// MARK: -

private protocol InitializableWithAny {
    init(value: Any, codingPath: [CodingKey]) throws
}

extension InitializableWithAny where Self: InitializableWithNumeric {
    fileprivate init(value: Any, codingPath: [CodingKey]) throws {
        let type = Self.self
        
        switch value {
        case let num as Int:
            guard let exactNum = Self(precisely: num) else {
                throw Error.dataCorrupted(codingPath: codingPath, expectation: type, reality: num)
            }
            self = exactNum
        case let num as Int8:
            guard let exactNum = Self(precisely: num) else {
                throw Error.dataCorrupted(codingPath: codingPath, expectation: type, reality: num)
            }
            self = exactNum
        case let num as Int16:
            guard let exactNum = Self(precisely: num) else {
                throw Error.dataCorrupted(codingPath: codingPath, expectation: type, reality: num)
            }
            self = exactNum
        case let num as Int32:
            guard let exactNum = Self(precisely: num) else {
                throw Error.dataCorrupted(codingPath: codingPath, expectation: type, reality: num)
            }
            self = exactNum
        case let num as Int64:
            guard let exactNum = Self(precisely: num) else {
                throw Error.dataCorrupted(codingPath: codingPath, expectation: type, reality: num)
            }
            self = exactNum
        case let num as UInt:
            guard let exactNum = Self(precisely: num) else {
                throw Error.dataCorrupted(codingPath: codingPath, expectation: type, reality: num)
            }
            self = exactNum
        case let num as UInt8:
            guard let exactNum = Self(precisely: num) else {
                throw Error.dataCorrupted(codingPath: codingPath, expectation: type, reality: num)
            }
            self = exactNum
        case let num as UInt16:
            guard let exactNum = Self(precisely: num) else {
                throw Error.dataCorrupted(codingPath: codingPath, expectation: type, reality: num)
            }
            self = exactNum
        case let num as UInt32:
            guard let exactNum = Self(precisely: num) else {
                throw Error.dataCorrupted(codingPath: codingPath, expectation: type, reality: num)
            }
            self = exactNum
        case let num as UInt64:
            guard let exactNum = Self(precisely: num) else {
                throw Error.dataCorrupted(codingPath: codingPath, expectation: type, reality: num)
            }
            self = exactNum
        case let num as Float:
            guard let exactNum = Self(precisely: num) else {
                throw Error.dataCorrupted(codingPath: codingPath, expectation: type, reality: num)
            }
            self = exactNum
        case let num as Double:
            guard let exactNum = Self(precisely: num) else {
                throw Error.dataCorrupted(codingPath: codingPath, expectation: type, reality: num)
            }
            self = exactNum
            #if os(macOS)
        case let num as Float80:
            guard let exactNum = Self(equalTo: num) else {
                throw Error.dataCorrupted(codingPath: codingPath, expectation: type, reality: num)
            }
            self = exactNum
            #endif
        default:
            throw Error.typeMismatch(codingPath: codingPath, expectation: type, reality: value)
        }
    }
}

extension Int: InitializableWithAny {}
extension Int8: InitializableWithAny {}
extension Int16: InitializableWithAny {}
extension Int32: InitializableWithAny {}
extension Int64: InitializableWithAny {}
extension UInt: InitializableWithAny {}
extension UInt8: InitializableWithAny {}
extension UInt16: InitializableWithAny {}
extension UInt32: InitializableWithAny {}
extension UInt64: InitializableWithAny {}
extension Float: InitializableWithAny {}
extension Double: InitializableWithAny {}

extension Bool: InitializableWithAny {
    fileprivate init(value: Any, codingPath: [CodingKey]) throws {
        let type = Bool.self
        guard let boolean = value as? Bool else {
            throw Error.typeMismatch(codingPath: codingPath, expectation: type, reality: value)
        }
        self = boolean
    }
}

extension String: InitializableWithAny {
    fileprivate init(value: Any, codingPath: [CodingKey]) throws {
        let type = String.self
        guard let string = value as? String else {
            throw Error.typeMismatch(codingPath: codingPath, expectation: type, reality: value)
        }
        self = string
    }
}

// MARK: -

// TODO: Xcode 10부터 init?<Source>(exactly: Source)가 지원된다. 이걸 바로 써도 되는지 확인해볼 것.
// NaN 처리 때문에 안 될 것 같다. JSONDecoder를 참고하면 될 듯
// https://github.com/apple/swift/blob/master/stdlib/public/Darwin/Foundation/JSONEncoder.swift
private protocol InitializableWithNumeric {
    init?<T>(precisely source: T) where T: BinaryInteger
    init?<T>(precisely source: T) where T: BinaryFloatingPoint
}

extension InitializableWithNumeric where Self: BinaryInteger {
    fileprivate init?<T>(precisely source: T) where T: BinaryInteger {
        self.init(exactly: source)
    }
    
    fileprivate init?<T>(precisely source: T) where T: BinaryFloatingPoint {
        self.init(exactly: source)
    }
}

extension Int: InitializableWithNumeric {}
extension Int8: InitializableWithNumeric {}
extension Int16: InitializableWithNumeric {}
extension Int32: InitializableWithNumeric {}
extension Int64: InitializableWithNumeric {}
extension UInt: InitializableWithNumeric {}
extension UInt8: InitializableWithNumeric {}
extension UInt16: InitializableWithNumeric {}
extension UInt32: InitializableWithNumeric {}
extension UInt64: InitializableWithNumeric {}

extension Float: InitializableWithNumeric {
    fileprivate init?<T>(precisely source: T) where T: BinaryInteger {
        // Generic 버전은 실제로는 구현이 없는 것 같다. 그래서 타입 별로 일일이 구현해야 한다.
        // https://github.com/apple/swift/blob/master/stdlib/public/core/FloatingPointTypes.swift.gyb
        // TODO: 2018.10.01에 수정된 거 같다. generic 버전이 잘 되는지 검증이 필요하다.
        // https://github.com/apple/swift/commit/0707ca6dacdb40cfbfeb1bee532a5802cd973655
        switch source {
        case let value as Int:
            guard let exactValue = Float(exactly: value) else { return nil }
            self = exactValue
        case let value as Int8:
            guard let exactValue = Float(exactly: value) else { return nil }
            self = exactValue
        case let value as Int16:
            guard let exactValue = Float(exactly: value) else { return nil }
            self = exactValue
        case let value as Int32:
            guard let exactValue = Float(exactly: value) else { return nil }
            self = exactValue
        case let value as Int64:
            guard let exactValue = Float(exactly: value) else { return nil }
            self = exactValue
        case let value as UInt:
            guard let exactValue = Float(exactly: value) else { return nil }
            self = exactValue
        case let value as UInt8:
            guard let exactValue = Float(exactly: value) else { return nil }
            self = exactValue
        case let value as UInt16:
            guard let exactValue = Float(exactly: value) else { return nil }
            self = exactValue
        case let value as UInt32:
            guard let exactValue = Float(exactly: value) else { return nil }
            self = exactValue
        case let value as UInt64:
            guard let exactValue = Float(exactly: value) else { return nil }
            self = exactValue
        default:
            preconditionFailure("\(type(of: source)) type is not supported.")
        }
    }
    
    fileprivate init?<T>(precisely source: T) where T: BinaryFloatingPoint {
        // TODO: Xcode 10부터 generic으로 초기화하는게 지원되는 것 같다. 검증 후 적용 필요.
        switch source {
        case let value as Float:
            self = value
        case let value as Double:
            if value.isNaN {
                self = Float.nan
            } else if let exactValue = Float(exactly: value) {
                self = exactValue
            } else {
                return nil
            }
            #if os(macOS)
        case let value as Float80:
            if value.isNaN {
                self = Float.nan
            } else if let exactValue = Float(exactly: value) {
                self = exactValue
            } else {
                return nil
            }
            #endif
        default:
            preconditionFailure("\(type(of: source)) type is not supported.")
        }
    }
}

extension Double: InitializableWithNumeric {
    fileprivate init?<T>(precisely source: T) where T: BinaryInteger {
        switch source {
        case let value as Int:
            guard let exactValue = Double(exactly: value) else { return nil }
            self = exactValue
        case let value as Int8:
            guard let exactValue = Double(exactly: value) else { return nil }
            self = exactValue
        case let value as Int16:
            guard let exactValue = Double(exactly: value) else { return nil }
            self = exactValue
        case let value as Int32:
            guard let exactValue = Double(exactly: value) else { return nil }
            self = exactValue
        case let value as Int64:
            guard let exactValue = Double(exactly: value) else { return nil }
            self = exactValue
        case let value as UInt:
            guard let exactValue = Double(exactly: value) else { return nil }
            self = exactValue
        case let value as UInt8:
            guard let exactValue = Double(exactly: value) else { return nil }
            self = exactValue
        case let value as UInt16:
            guard let exactValue = Double(exactly: value) else { return nil }
            self = exactValue
        case let value as UInt32:
            guard let exactValue = Double(exactly: value) else { return nil }
            self = exactValue
        case let value as UInt64:
            guard let exactValue = Double(exactly: value) else { return nil }
            self = exactValue
        default:
            preconditionFailure("\(type(of: source)) type is not supported.")
        }
    }
    
    fileprivate init?<T>(precisely source: T) where T: BinaryFloatingPoint {
        switch source {
        case let value as Float:
            self = Double(value)
        case let value as Double:
            self = value
            #if os(macOS)
        case let value as Float80:
            if value.isNaN {
                self = Double.nan
            } else if let exactValue = Double(exactly: value) {
                self = exactValue
            } else {
                return nil
            }
            #endif
        default:
            preconditionFailure("\(type(of: source)) type is not supported.")
        }
    }
}



