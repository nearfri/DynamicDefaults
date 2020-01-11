import Foundation
import ObjectCoder

@dynamicMemberLookup
public struct UserDefaultsAccessor<Subject> {
    public let userDefaults: UserDefaults
    public let defaultValue: Subject
    public let keysByKeyPath: [PartialKeyPath<Subject>: String]
    
    public init(userDefaults: UserDefaults = .standard,
                defaultValue: Subject,
                keysByKeyPath: [PartialKeyPath<Subject>: String]) {
        self.userDefaults = userDefaults
        self.defaultValue = defaultValue
        self.keysByKeyPath = keysByKeyPath
    }
    
    public subscript<T: Codable>(dynamicMember keyPath: KeyPath<Subject, T>) -> T {
        get {
            return value(for: keyPath)
        }
        nonmutating set {
            setValue(newValue, for: keyPath)
        }
    }
    
    private func value<T: Codable>(for keyPath: KeyPath<Subject, T>) -> T {
        guard let value = userDefaults.object(forKey: key(for: keyPath)) else {
            return defaultValue[keyPath: keyPath]
        }
        
        // nil은 String으로 저장되므로 제외해야 한다.
        if let value = value as? T, !(value is String) {
            return value
        }
        
        do {
            return try ObjectDecoder().decode(T.self, from: value)
        } catch {
            print("Failed to decode \(T.self). Underlying error: \(error)")
            userDefaults.removeObject(forKey: key(for: keyPath))
            return defaultValue[keyPath: keyPath]
        }
    }
    
    private func key<T: Codable>(for keyPath: KeyPath<Subject, T>,
                                 file: StaticString = #file,
                                 line: UInt = #line) -> String {
        guard let result = keysByKeyPath[keyPath] else {
            preconditionFailure("No key associated with keyPath.")
        }
        return result
    }
    
    private func setValue<T: Codable>(_ value: T, for keyPath: KeyPath<Subject, T>) {
        let encodedValue: Any
        switch value {
        case is NSNumber, is String, is Data, is Date:
            encodedValue = value
        default:
            do {
                encodedValue = try ObjectEncoder().encode(value)
            } catch {
                preconditionFailure("Failed to encode \(T.self). Underlying error: \(error)")
            }
        }
        
        userDefaults.set(encodedValue, forKey: key(for: keyPath))
    }
}
