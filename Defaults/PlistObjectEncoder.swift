
import Foundation

// ref.: https://github.com/apple/swift/blob/master/stdlib/public/SDK/Foundation/PlistEncoder.swift

public class PlistObjectEncoder: Encoder {
    public private(set) var codingPath: [CodingKey]
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    fileprivate var storage: PlistObjectEncodingStorage = PlistObjectEncodingStorage()
    
    public init(codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
    }
    
    public func container<Key>(keyedBy type: Key.Type
        ) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        
        fatalError()
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        fatalError()
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        fatalError()
    }
}

private struct PlistObjectEncodingStorage {
    private(set) var containers: [Any] = []
    
    var count: Int {
        return containers.count
    }
    
    mutating func pushKeyedContainer() -> NSMutableDictionary {
        let dictionary = NSMutableDictionary()
        containers.append(dictionary)
        return dictionary
    }
    
    mutating func pushUnkeyedContainer() -> NSMutableArray {
        let array = NSMutableArray()
        containers.append(array)
        return array
    }
    
    mutating func push(container: Any) {
        containers.append(container)
    }
    
    mutating func popContainer() -> Any {
        guard let result = containers.popLast() else {
            preconditionFailure("Empty container stack.")
        }
        return result
    }
}



private extension PlistObjectEncoder {
    func box<T: Encodable>(_ value: T) throws -> Any {
        if T.self == Date.self || T.self == Data.self || T.self == URL.self {
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

private class PlistObjectReferencingEncoder: PlistObjectEncoder {
    private enum Reference {
        case array(NSMutableArray, Int)
        case dictionary(NSMutableDictionary, String)
    }
    
    private let encoder: PlistObjectEncoder
    private let reference: Reference
    
    init(referencing encoder: PlistObjectEncoder, at index: Int, wrapping array: NSMutableArray) {
        self.encoder = encoder
        self.reference = .array(array, index)
        let codingPath = encoder.codingPath + [PlistObjectKey(index: index)]
        super.init(codingPath: codingPath)
    }
    
    init(referencing encoder: PlistObjectEncoder, at key: CodingKey,
         wrapping dictionary: NSMutableDictionary) {
        self.encoder = encoder
        self.reference = .dictionary(dictionary, key.stringValue)
        let codingPath = encoder.codingPath + [key]
        super.init(codingPath: codingPath)
    }
    
    deinit {
        let value: Any
        switch storage.count {
        case 0:
            value = [:] as [String: Any]
        case 1:
            value = storage.popContainer()
        default:
            fatalError("Referencing encoder deallocated with multiple containers on stack.")
        }
        
        switch reference {
        case let .array(array, index):
            array.insert(value, at: index)
        case let .dictionary(dictionary, key):
            dictionary[key] = value
        }
    }
    
    var canEncodeNewValue: Bool {
        return storage.count == codingPath.count - encoder.codingPath.count - 1
    }
}



