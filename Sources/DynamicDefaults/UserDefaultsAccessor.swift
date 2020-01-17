import Foundation
import ObjectCoder

@dynamicMemberLookup
public class UserDefaultsAccessor<Subject> {
    private let userDefaults: UserDefaults
    private let defaultSubject: Subject
    private let keysByKeyPath: [PartialKeyPath<Subject>: String]
    
    public init(userDefaults: UserDefaults = .standard,
                defaultSubject: Subject,
                keysByKeyPath: [PartialKeyPath<Subject>: String]) {
        self.userDefaults = userDefaults
        self.defaultSubject = defaultSubject
        self.keysByKeyPath = keysByKeyPath
    }
    
    public func key<T: Codable>(for keyPath: KeyPath<Subject, T>) -> String {
        guard let result = keysByKeyPath[keyPath] else {
            preconditionFailure("No key associated with keyPath.")
        }
        return result
    }
    
    public subscript<T: Codable>(dynamicMember keyPath: KeyPath<Subject, T>) -> T {
        get {
            return value(for: keyPath)
        }
        set {
            setValue(newValue, for: keyPath)
        }
    }
    
    private func value<T: Codable>(for keyPath: KeyPath<Subject, T>) -> T {
        guard let value = userDefaults.object(forKey: key(for: keyPath)) else {
            return defaultSubject[keyPath: keyPath]
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
            return defaultSubject[keyPath: keyPath]
        }
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
