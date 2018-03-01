
import Foundation

// Inspired by https://gist.github.com/macmade/0824d91b1f3a3b095057a40742d50a03
// TODO: 마이그레이션 지원

public protocol SubPreferences: NSObjectProtocol {}

open class BasePreferences: NSObject {
    private let userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        super.init()
        
        precondition(type(of: self) != BasePreferences.self,
                     "This class must be subclassed before it can be used.")
        
        for each in persistentKeyPaths {
            print(each)
        }
        registerDefaults()
        synchronizeProperties()
        addPropertyObserver()
    }
    
    deinit {
        removePropertyObserver()
    }
    
    private func registerDefaults() {
        let defaults: [(String, Any)] = persistentKeyPaths.reduce(into: []) { (ret, keyPath) in
            value(forKeyPath: keyPath).map({ ret.append((keyPath, $0)) })
        }
        userDefaults.register(defaults: Dictionary(uniqueKeysWithValues: defaults))
    }
    
    private func synchronizeProperties() {
        for keyPath in persistentKeyPaths {
            setValue(userDefaults.object(forKey: keyPath), forKeyPath: keyPath)
        }
    }
    
    private func addPropertyObserver() {
        for keyPath in persistentKeyPaths {
            addObserver(self, forKeyPath: keyPath, options: [.new], context: &KVO.context)
        }
    }
    
    private func removePropertyObserver() {
        for keyPath in persistentKeyPaths {
            removeObserver(self, forKeyPath: keyPath, context: &KVO.context)
        }
    }
    
    open var persistentKeyPaths: [String] {
        return propertyKeyPaths(of: self)
    }
    
    private func propertyKeyPaths(of subject: Any) -> [String] {
        var result: [String] = []
        for case let (label?, value) in Mirror(reflecting: subject).children {
            if value is SubPreferences {
                let subKeyPaths = propertyKeyPaths(of: value)
                result.append(contentsOf: subKeyPaths.map({ "\(label).\($0)" }))
            } else {
                result.append(label)
            }
        }
        return result
    }
    
    open override func observeValue(
        forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?) {
        
        if context == &KVO.context {
            if let keyPath = keyPath, let change = change {
                if let newValue = change[NSKeyValueChangeKey.newKey], !(newValue is NSNull) {
                    userDefaults.set(newValue, forKey: keyPath)
                } else {
                    userDefaults.removeObject(forKey: keyPath)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

extension BasePreferences {
    private enum KVO {
        static var context: Int = 0
    }
}



