import Foundation

public protocol KeyValueObservation: AnyObject {
    // A KeyValueObservation instance must call invalidate() when deinitialized.
    func invalidate()
}

public protocol KeyValueStore: AnyObject {
    func value(forKey key: String) -> Any?
    func setValue(_ value: Any, forKey key: String)
    func removeValue(forKey key: String)
    
    @discardableResult
    func synchronize() -> Bool
    
    func observeValue(forKey key: String,
                      changeHandler: @escaping () -> Void) -> KeyValueObservation
}
