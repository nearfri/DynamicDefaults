import Foundation

public protocol KeyValueStore {
    func object(forKey key: String) -> Any?
    func set(_ object: Any?, forKey key: String)
    func removeObject(forKey key: String)
    func synchronize() -> Bool
}

extension UserDefaults: KeyValueStore {}

#if os(iOS) || os(macOS) || os(tvOS)
extension NSUbiquitousKeyValueStore: KeyValueStore {}
#endif
