import Foundation

public protocol ValueCoder: AnyObject {
    func encode<T: Encodable>(_ value: T) throws -> Any
    func decode<T: Decodable>(_ type: T.Type, from value: Any) throws -> T
}
