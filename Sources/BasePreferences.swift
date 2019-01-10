
import Foundation

open class BasePreferences {
    internal private(set) var userDefaults: UserDefaults = .standard
    
    public required init() {}
    
    public static func instantiate<T: BasePreferences>(
        _ type: T.Type, userDefaults: UserDefaults = .standard) -> T where T: Codable {
        
        do {
            let encoder = ObjectEncoder()
            guard let defaultValues = try encoder.encode(type.init()) as? [String: Any] else {
                preconditionFailure("Expected to encode \(type) as dictionary, but it was not.")
            }
            
            let storedValues = userDefaults.dictionaryRepresentation()
            let mergedValues = defaultValues.merging(storedValues) { (_, stored) in stored }
            
            let result = try ObjectDecoder().decode(type, from: mergedValues)
            result.userDefaults = userDefaults
            
            return result
        } catch {
            preconditionFailure("Failed to encode \(type): \(error)")
        }
    }
    
    public func store<T: Encodable>(_ value: T?, forKey key: String = #function) {
        do {
            userDefaults.set(try encode(value), forKey: key)
        } catch {
            preconditionFailure("Failed to encode value for key \"\(key)\": \(error)")
        }
    }
    
    private func encode<T: Encodable>(_ value: T?) throws -> Any {
        guard let value = value else {
            return NilEncodingStrategy.defaultNilSymbol
        }
        
        switch value {
        case is NSNumber, is String, is Data, is Date:
            return value
        default:
            return try ObjectEncoder().encode(value)
        }
    }
}



