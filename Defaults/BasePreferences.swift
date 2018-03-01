
import Foundation

// Inspired by https://gist.github.com/macmade/0824d91b1f3a3b095057a40742d50a03
// TODO: 마이그레이션 지원
// TODO: 커스텀 타입과 keyPath 지원??

open class BasePreferences: NSObject {
    private let userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        super.init()
        
        registerDefaults()
        synchronizeProperties()
        addPropertyObserver()
    }
    
    deinit {
        removePropertyObserver()
    }
    
    private func registerDefaults() {
        let defaults: [(String, Any)] = defaultNames.reduce(into: []) { (ret, key) in
            value(forKey: key).map({ ret.append((key, $0)) })
        }
        userDefaults.register(defaults: Dictionary(uniqueKeysWithValues: defaults))
    }
    
    private func synchronizeProperties() {
        for key in defaultNames {
            setValue(userDefaults.object(forKey: key), forKey: key)
        }
    }
    
    private func addPropertyObserver() {
        for key in defaultNames {
            addObserver(self, forKeyPath: key, options: [.new], context: &KVO.context)
        }
    }
    
    private func removePropertyObserver() {
        for key in defaultNames {
            removeObserver(self, forKeyPath: key, context: &KVO.context)
        }
    }
    
    open var defaultNames: [String] {
        let names = Set(Mirror(reflecting: self).children.flatMap({ $0.label }))
        let filteredNames = names.subtracting(["userDefaults"])
        return Array(filteredNames)
    }
    
    open override func observeValue(
        forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?) {
        
        if context == &KVO.context {
            if let key = keyPath, let change = change {
                userDefaults.set(change[NSKeyValueChangeKey.newKey], forKey: key)
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



