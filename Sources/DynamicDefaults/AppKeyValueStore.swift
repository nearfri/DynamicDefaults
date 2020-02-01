import Foundation

public class AppKeyValueStore: KeyValueStore {
    public let defaults: UserDefaults
    
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    public func value(forKey key: String) -> Any? {
        return defaults.object(forKey: key)
    }
    
    public func setValue(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }
    
    public func removeValue(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
    
    public func synchronize() -> Bool {
        defaults.synchronize()
    }
}
