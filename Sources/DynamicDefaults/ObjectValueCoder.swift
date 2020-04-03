import Foundation
import ObjectCoder

public class ObjectValueCoder: ValueCoder {
    private let encoder: ObjectEncoder
    private let decoder: ObjectDecoder
    
    public init() {
        encoder = ObjectEncoder()
        decoder = ObjectDecoder()
    }
    
    public func encode<T: Encodable>(_ value: T) throws -> Any {
        switch value {
        case is NSNumber, is String, is Data, is Date:
            return value
        default:
            return try ObjectEncoder().encode(value)
        }
    }
    
    public func decode<T: Decodable>(_ type: T.Type, from value: Any) throws -> T {
        switch value {
        case let value as T where !(value is String):
            // ObjectCoder가 nil은 String으로 저장하므로 제외해야 한다.
            return value
        default:
            return try ObjectDecoder().decode(T.self, from: value)
        }
    }
}
