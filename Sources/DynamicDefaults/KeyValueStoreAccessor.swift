import Foundation

@dynamicMemberLookup
open class KeyValueStoreAccessor<Subject> {
    private let keyValueStore: KeyValueStore
    private let valueCoder: ValueCoder
    private let defaultSubject: Subject
    private let keysByKeyPath: [PartialKeyPath<Subject>: String]
    
    public init(keyValueStore: KeyValueStore = AppKeyValueStore(),
                valueCoder: ValueCoder = ObjectValueCoder(),
                defaultSubject: Subject,
                keysByKeyPath: [PartialKeyPath<Subject>: String]) {
        self.keyValueStore = keyValueStore
        self.valueCoder = valueCoder
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
        do {
            guard let value = keyValueStore.value(forKey: key(for: keyPath)) else {
                return defaultSubject[keyPath: keyPath]
            }
            return try valueCoder.decode(T.self, from: value)
        } catch {
            print("Failed to decode \(T.self). Underlying error: \(error)")
            keyValueStore.removeValue(forKey: key(for: keyPath))
            return defaultSubject[keyPath: keyPath]
        }
    }
    
    private func setValue<T: Codable>(_ value: T, for keyPath: KeyPath<Subject, T>) {
        do {
            let encodedValue = try valueCoder.encode(value)
            keyValueStore.setValue(encodedValue, forKey: key(for: keyPath))
        } catch {
            preconditionFailure("Failed to encode \(T.self). Underlying error: \(error)")
        }
    }
    
    @discardableResult
    public func synchronize() -> Bool {
        return keyValueStore.synchronize()
    }
    
    public func hasStoredValue<T: Codable>(for keyPath: KeyPath<Subject, T>) -> Bool {
        return keyValueStore.value(forKey: key(for: keyPath)) != nil
    }
    
    public func removeStoredValue<T: Codable>(for keyPath: KeyPath<Subject, T>) {
        keyValueStore.removeValue(forKey: key(for: keyPath))
    }
    
    public func removeAllStoredValues() {
        keysByKeyPath.values.forEach(keyValueStore.removeValue(forKey:))
    }
    
    public func observe<T: Codable>(_ keyPath: KeyPath<Subject, T>,
                                    changeHandler: @escaping (T) -> Void) -> KeyValueObservation {
        return keyValueStore.observeValue(forKey: key(for: keyPath)) { [weak self] in
            guard let self = self else { return }
            changeHandler(self.value(for: keyPath))
        }
    }
}
