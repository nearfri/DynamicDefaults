import Foundation

#if os(iOS) || os(macOS) || os(tvOS)

public class SharedKeyValueStore: KeyValueStore {
    public let store: NSUbiquitousKeyValueStore
    private let internalObserverRegistry: StoreInternalObserverRegistry
    
    public init(store: NSUbiquitousKeyValueStore = .default) {
        self.store = store
        self.internalObserverRegistry = StoreInternalObserverRegistry()
    }
    
    public func value(forKey key: String) -> Any? {
        return store.object(forKey: key)
    }
    
    public func setValue(_ value: Any, forKey key: String) {
        store.set(value, forKey: key)
        internalObserverRegistry.notifyOfValueChange(forKey: key)
    }
    
    public func removeValue(forKey key: String) {
        store.removeObject(forKey: key)
        internalObserverRegistry.notifyOfValueChange(forKey: key)
    }
    
    @discardableResult
    public func synchronize() -> Bool {
        store.synchronize()
    }
    
    public func observeValue(forKey key: String,
                             changeHandler: @escaping () -> Void) -> KeyValueObservation {
        let internalObserver = StoreInternalObserver(registry: internalObserverRegistry,
                                                     key: key,
                                                     handler: changeHandler)
        internalObserver.startObserving()
        
        let externalObserver = StoreExternalObserver(store: store, key: key, handler: changeHandler)
        externalObserver.startObserving()
        
        return StoreObserverPair(internalObserver: internalObserver,
                                 externalObserver: externalObserver)
    }
}

private class StoreObserverPair: KeyValueObservation {
    private let internalObserver: StoreInternalObserver
    private let externalObserver: StoreExternalObserver
    
    init(internalObserver: StoreInternalObserver, externalObserver: StoreExternalObserver) {
        self.internalObserver = internalObserver
        self.externalObserver = externalObserver
    }
    
    deinit {
        invalidate()
    }
    
    func invalidate() {
        internalObserver.invalidate()
        externalObserver.invalidate()
    }
}

private class StoreExternalObserver: NSObject, KeyValueObservation {
    private weak var store: NSUbiquitousKeyValueStore?
    private let key: String
    private let handler: () -> Void
    
    init(store: NSUbiquitousKeyValueStore, key: String, handler: @escaping () -> Void) {
        self.store = store
        self.key = key
        self.handler = handler
        super.init()
    }
    
    deinit {
        invalidate()
    }
    
    func invalidate() {
        guard let store = store else { return }
        
        let nc = NotificationCenter.default
        nc.removeObserver(self,
                          name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                          object: store)
        self.store = nil
    }
    
    func startObserving() {
        guard let store = store else { return }
        
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(storeDidChangeExternally(_:)),
                       name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                       object: store)
    }
    
    @objc private func storeDidChangeExternally(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let keys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
            else { return }
        
        if keys.contains(key) {
            handler()
        }
    }
}

private class StoreInternalObserverRegistry {
    private var observersByKey: [String: Set<StoreInternalObserver>] = [:]
    
    func register(_ observer: StoreInternalObserver) {
        observersByKey[observer.key, default: []].insert(observer)
    }
    
    func unregister(_ observer: StoreInternalObserver) {
        observersByKey[observer.key]?.remove(observer)
        
        if observersByKey[observer.key]?.isEmpty == true {
            observersByKey[observer.key] = nil
        }
    }
    
    func notifyOfValueChange(forKey key: String) {
        guard let observers = observersByKey[key] else { return }
        for observer in observers {
            observer.handler()
        }
    }
}

private class StoreInternalObserver {
    private weak var registry: StoreInternalObserverRegistry?
    let key: String
    let handler: () -> Void
    
    init(registry: StoreInternalObserverRegistry, key: String, handler: @escaping () -> Void) {
        self.registry = registry
        self.key = key
        self.handler = handler
    }
    
    deinit {
        invalidate()
    }
    
    func invalidate() {
        registry?.unregister(self)
        registry = nil
    }
    
    func startObserving() {
        registry?.register(self)
    }
}

extension StoreInternalObserver: Hashable {
    static func == (lhs: StoreInternalObserver, rhs: StoreInternalObserver) -> Bool {
        return lhs === rhs
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

#endif
