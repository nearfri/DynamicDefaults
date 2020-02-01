import Foundation

#if os(iOS) || os(macOS) || os(tvOS)
public class SharedKeyValueStore: KeyValueStore {
    public let store: NSUbiquitousKeyValueStore
    
    public init(store: NSUbiquitousKeyValueStore = .default) {
        self.store = store
    }
    
    public func value(forKey key: String) -> Any? {
        return store.object(forKey: key)
    }
    
    public func setValue(_ value: Any?, forKey key: String) {
        store.set(value, forKey: key)
    }
    
    public func removeValue(forKey key: String) {
        store.removeObject(forKey: key)
    }
    
    public func synchronize() -> Bool {
        store.synchronize()
    }
}
#endif
