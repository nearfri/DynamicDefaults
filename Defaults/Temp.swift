
import Foundation

open class BasePreferences2: NSObject {
    private let userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        super.init()
        
        precondition(type(of: self) != BasePreferences.self,
                     "This class must be subclassed before it can be used.")
        
        migrateUserDefaults(userDefaults)
        registerDefaults()
        synchronizeProperties()
        addPropertyObserver()
    }
    
    deinit {
        removePropertyObserver()
    }
    
    open func migrateUserDefaults(_ userDefaults: UserDefaults) {
        
    }
    
    open var persistentKeys: [String] {
        var result: [String] = Array(optionalValueTypes.keys)
        for case let (label?, value) in Mirror(reflecting: self).children {
            guard let unwrappedValue = wrapIfNonOptional(value) else { continue }
            guard type(of: unwrappedValue) is Codable.Type else { continue }
            result.append(label)
        }
        return result
    }
    
    open var optionalValueTypes: [String: Codable.Type] {
        return [:]
    }
    
    private func valueType(for persistentKey: String) -> Codable.Type {
        let mirror = Mirror(reflecting: self)
        guard let value = mirror.descendant(persistentKey) else {
            preconditionFailure("No value found for key \"\(persistentKey)\".")
        }
        
        if let unwrappedValue = wrapIfNonOptional(value) {
            guard let result = type(of: unwrappedValue) as? Codable.Type else {
                preconditionFailure("\(type(of: unwrappedValue)) is not Codable.Type.")
            }
            return result
        }
        
        guard let result = optionalValueTypes[persistentKey] else {
            preconditionFailure("Cannot get value type for key \"\(persistentKey)\" -- "
                + "\"optionalValueTypes\" doesn’t contain the key.")
        }
        return result
    }
    
    private func wrapIfNonOptional(_ value: Any) -> Any? {
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            return mirror.children.first?.value
        }
        return value
    }
    
    private func registerDefaults() {
        let defaults: [String: Any] = persistentKeys.reduce(into: [:]) { (ret, key) in
            let value = self.value(forKey: key)
            do {
                let object = try encode(value)
                ret[key] = object
            } catch {
                preconditionFailure("\(error)")
            }
        }
        userDefaults.register(defaults: defaults)
    }
    
    private func synchronizeProperties() {
        for key in persistentKeys {
            guard let object = userDefaults.object(forKey: key) else { continue }
            do {
                let value = try decode(valueType(for: key), from: object)
                setValue(value, forKey: key)
            } catch {
                assertionFailure("\(error)")
            }
        }
    }
    
    private func encode(_ value: Any?) throws -> Any {
        guard let value = value else {
            return ObjectEncoder().nilSymbol
        }
        
        switch value {
        case is NSNumber, is String:
            return value
        default:
            fatalError()
        }
    }
    
    private func decode(_ type: Decodable.Type, from object: Any) throws -> Any? {
        switch object {
        case is NSNumber, is String:
            return object
        default:
            fatalError()
        }
    }
    
    
    private func addPropertyObserver() {
        for key in persistentKeys {
            addObserver(self, forKeyPath: key, options: [.new], context: &KVO.context)
        }
    }
    
    private func removePropertyObserver() {
        for key in persistentKeys {
            removeObserver(self, forKeyPath: key, context: &KVO.context)
        }
    }
    
    open override func observeValue(
        forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?) {
        
        guard context == &KVO.context else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        guard let keyPath = keyPath, let change = change else { return }
        
        let value: Encodable? = {
            if let newValue = change[NSKeyValueChangeKey.newKey], !(newValue is NSNull) {
                return (newValue as! Encodable)
            }
            return nil
        }()
        
        do {
            let encodedObject = try encode(value)
            userDefaults.set(encodedObject, forKey: keyPath)
        } catch {
            preconditionFailure("\(error)")
        }
    }
}

extension BasePreferences2 {
    private enum KVO {
        static var context: Int = 0
    }
}



