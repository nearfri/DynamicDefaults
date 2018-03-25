
import Foundation

// ref.: https://github.com/apple/swift/blob/master/stdlib/public/SDK/Foundation/PlistEncoder.swift

public class PlistObjectDecoder: Decoder {
    public private(set) var codingPath: [CodingKey]
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    private var storage: Storage = Storage()
    
    private init(codingPath: [CodingKey]) {
        self.codingPath = codingPath
    }
    
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        fatalError()
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError()
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        fatalError()
    }
}

extension PlistObjectDecoder {
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
    }
}



