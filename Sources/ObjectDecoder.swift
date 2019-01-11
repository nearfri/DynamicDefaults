
import Foundation

// ref.: https://github.com/apple/swift/blob/master/stdlib/public/Darwin/Foundation/PlistEncoder.swift

public class ObjectDecoder: Decoder {
    public private(set) var codingPath: [CodingKey]
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    public var nilDecodingStrategy: NilDecodingStrategy = .default
    public var passthroughTypes: [Decodable.Type] = [Data.self, Date.self]
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
        
        switch storage.topContainer {
        case let topContainer as [String: Any]:
            let decodingContainer = KeyedObjectDecodingContainer<Key>(
                referencing: self, codingPath: codingPath, container: topContainer)
            return KeyedDecodingContainer(decodingContainer)
            
        case let topContainer where nilDecodingStrategy.isNilValue(topContainer):
            let desc = "Cannot get keyed decoding container -- found nil value instead."
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: desc)
            throw DecodingError.valueNotFound(KeyedDecodingContainer<Key>.self, context)
            
        default:
            throw Error.typeMismatch(codingPath: codingPath, expectation: [String: Any].self,
                                     reality: storage.topContainer)
        }
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        switch storage.topContainer {
        case let topContainer as [Any]:
            return UnkeyedObjectDecodingContainer(
                referencing: self, codingPath: codingPath, container: topContainer)
            
        case let topContainer where nilDecodingStrategy.isNilValue(topContainer):
            let desc = "Cannot get unkeyed decoding container -- found nil value instead."
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: desc)
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self, context)
            
        default:
            throw Error.typeMismatch(codingPath: codingPath, expectation: [Any].self,
                                     reality: storage.topContainer)
        }
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
        
        if Swift.type(of: object) == type, isPassthroughType(type) {
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
        if let value = value as? T, isPassthroughType(type) {
            return value
        }
        
        storage.pushContainer(value)
        defer { storage.popContainer() }
        
        return try type.init(from: self)
    }
    
    private func isPassthroughType(_ type: Decodable.Type) -> Bool {
        return passthroughTypes.contains(where: { type == $0 })
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
            if decoder.nilDecodingStrategy.isNilValue(value) {
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
            
            decoder.codingPath.append(key)
            defer { decoder.codingPath.removeLast() }
            
            return try decoder.unbox(value, as: type)
        }
        
        private func value(forKey key: Key) throws -> Any {
            guard let result = container[key.stringValue] else {
                // Error의 codingPath는 container가 아니라 decoder의 것으로 한다.
                throw Error.keyNotFound(codingPath: decoder.codingPath, key: key)
            }
            return result
        }
        
        private func decodeValue<T: InitializableWithAny>(
            type: T.Type, forKey key: Key) throws -> T {
            
            let value = try self.value(forKey: key)
            if decoder.nilDecodingStrategy.isNilValue(value) {
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
            
            let value = container[currentIndex]
            if decoder.nilDecodingStrategy.isNilValue(value) {
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
            
            let key = ObjectKey(index: currentIndex)
            let value = container[currentIndex]
            if decoder.nilDecodingStrategy.isNilValue(value) {
                throw Error.valueNotFound(codingPath: decoder.codingPath + [key], expectation: type)
            }
            
            let decodedValue = try type.init(value: value, codingPath: decoder.codingPath + [key])
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
            return decoder.nilDecodingStrategy.isNilValue(value)
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
        
        func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
            return try decoder.unbox(decoder.storage.topContainer, as: type)
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
            guard let exactNum = Self(precisely: num) else {
                throw Error.dataCorrupted(codingPath: codingPath, expectation: type, reality: num)
            }
            self = exactNum
            #endif
        default:
            throw Error.typeMismatch(codingPath: codingPath, expectation: type, reality: value)
        }
    }
}

// MARK: -

private protocol InitializableWithNumeric {
    init?<T>(precisely source: T) where T: BinaryInteger
    init?<T>(precisely source: T) where T: BinaryFloatingPoint
}

extension InitializableWithNumeric where Self: Numeric {
    fileprivate init?<T>(precisely source: T) where T: BinaryInteger {
        self.init(exactly: source)
    }
}

extension InitializableWithNumeric where Self: BinaryInteger {
    fileprivate init?<T>(precisely source: T) where T: BinaryFloatingPoint {
        self.init(exactly: source)
    }
}

extension InitializableWithNumeric where Self: BinaryFloatingPoint {
    fileprivate init?<T>(precisely source: T) where T: BinaryFloatingPoint {
        if source.isNaN {
            self = Self.nan
        } else if let exactValue = Self(exactly: source) {
            self = exactValue
        } else {
            return nil
        }
    }
}

extension Int: InitializableWithAny, InitializableWithNumeric {}
extension Int8: InitializableWithAny, InitializableWithNumeric {}
extension Int16: InitializableWithAny, InitializableWithNumeric {}
extension Int32: InitializableWithAny, InitializableWithNumeric {}
extension Int64: InitializableWithAny, InitializableWithNumeric {}
extension UInt: InitializableWithAny, InitializableWithNumeric {}
extension UInt8: InitializableWithAny, InitializableWithNumeric {}
extension UInt16: InitializableWithAny, InitializableWithNumeric {}
extension UInt32: InitializableWithAny, InitializableWithNumeric {}
extension UInt64: InitializableWithAny, InitializableWithNumeric {}
extension Float: InitializableWithAny, InitializableWithNumeric {}
extension Double: InitializableWithAny, InitializableWithNumeric {}
#if os(macOS)
extension Float80: InitializableWithAny, InitializableWithNumeric {}
#endif



