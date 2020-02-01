import Foundation

public protocol KeyValueStore: AnyObject {
    func value(forKey key: String) -> Any?
    func setValue(_ value: Any?, forKey key: String)
    func removeValue(forKey key: String)
    func synchronize() -> Bool
}
