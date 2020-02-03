import Foundation

public class AppKeyValueStore: KeyValueStore {
    public let defaults: UserDefaults
    
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    public func value(forKey key: String) -> Any? {
        return defaults.object(forKey: key)
    }
    
    public func setValue(_ value: Any, forKey key: String) {
        defaults.set(value, forKey: key)
    }
    
    public func removeValue(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
    
    @discardableResult
    public func synchronize() -> Bool {
        defaults.synchronize()
    }
    
    public func observeValue(forKey key: String,
                             changeHandler: @escaping () -> Void) -> KeyValueObservation {
        let observer = DefaultsObserver(defaults: defaults, key: key, handler: changeHandler)
        observer.startObserving()
        return observer
    }
}

private class DefaultsObserver: NSObject, KeyValueObservation {
    private weak var defaults: UserDefaults?
    private let key: String
    private let handler: () -> Void
    
    init(defaults: UserDefaults, key: String, handler: @escaping () -> Void) {
        self.defaults = defaults
        self.key = key
        self.handler = handler
        super.init()
    }
    
    deinit {
        invalidate()
    }
    
    func invalidate() {
        defaults?.removeObserver(self, forKeyPath: key, context: nil)
        defaults = nil
    }
    
    func startObserving() {
        defaults?.addObserver(self, forKeyPath: key, options: [], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        handler()
    }
}
