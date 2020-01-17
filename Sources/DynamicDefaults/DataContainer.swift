import Foundation

public protocol DataContainer: AnyObject {
    var dictionaryRepresentation: [String: Any] { get }
    func set(_ value: Any, forKey key: String)
}

public class LocalDataContainer: DataContainer {
    let userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public var dictionaryRepresentation: [String: Any] {
        return userDefaults.dictionaryRepresentation()
    }
    
    public func set(_ value: Any, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
}

// SharedDataContainer has not been tested.
#if os(iOS) || os(macOS) || os(tvOS)
public class SharedDataContainer: DataContainer {
    let keyValueStore: NSUbiquitousKeyValueStore
    
    public init(keyValueStore: NSUbiquitousKeyValueStore) {
        self.keyValueStore = keyValueStore
    }
    
    public var dictionaryRepresentation: [String: Any] {
        return keyValueStore.dictionaryRepresentation
    }
    
    public func set(_ value: Any, forKey key: String) {
        keyValueStore.set(value, forKey: key)
    }
}
#endif
