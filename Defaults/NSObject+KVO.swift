
import Foundation

// ref.: https://github.com/apple/swift/blob/master/stdlib/public/SDK/Foundation/NSObject.swift

public struct KVOChange<Value> {
    public typealias Kind = NSKeyValueChange
    
    let kind: Kind
    let newValue: Value?
    let oldValue: Value?
    let indexes: IndexSet?
    let isPrior: Bool
}

public class KVOItem: NSObject {
    private weak var object: NSObject?
    private let keyPath: String
    private let handler: (NSObject, KVOChange<Any>) -> Void
    
    fileprivate init(object: NSObject, keyPath: String,
                     handler: @escaping (NSObject, KVOChange<Any>) -> Void) {
        self.object = object
        self.keyPath = keyPath
        self.handler = handler
        super.init()
    }
    
    deinit {
        invalidate()
    }
    
    public func invalidate() {
        object?.removeObserver(self, forKeyPath: keyPath, context: nil)
        object = nil
    }
    
    fileprivate func startObserving(options: NSKeyValueObservingOptions) {
        object?.addObserver(self, forKeyPath: keyPath, options: options, context: nil)
    }
    
    public override func observeValue(
        forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?) {
        
        guard let ourObject = self.object, object as? NSObject === ourObject,
            let change = change else { return }
        
        let rawKind = change[.kindKey] as! UInt
        let notification = KVOChange(kind: NSKeyValueChange(rawValue: rawKind)!,
                                     newValue: change[.newKey],
                                     oldValue: change[.oldKey],
                                     indexes: change[.indexesKey] as? IndexSet,
                                     isPrior: change[.notificationIsPriorKey] as? Bool ?? false)
        handler(ourObject, notification)
    }
}

public protocol KeyValueObserving {}

extension KeyValueObserving {
    public func observe<Value>(
        keyPath: String, options: NSKeyValueObservingOptions = [],
        changeHandler: @escaping (Self, KVOChange<Value>) -> Void) -> KVOItem {
        
        let result = KVOItem(object: self as! NSObject, keyPath: keyPath) { (obj, change) in
            let notification = KVOChange(kind: change.kind,
                                         newValue: change.newValue as? Value,
                                         oldValue: change.oldValue as? Value,
                                         indexes: change.indexes,
                                         isPrior: change.isPrior)
            changeHandler(obj as! Self, notification)
        }
        result.startObserving(options: options)
        return result
    }
    
    public func observe(
        keyPath: String, options: NSKeyValueObservingOptions = [],
        changeHandler: @escaping (Self, KVOChange<Any>) -> Void) -> KVOItem {
        
        let result = KVOItem(object: self as! NSObject, keyPath: keyPath) { (obj, change) in
            changeHandler(obj as! Self, change)
        }
        result.startObserving(options: options)
        return result
    }
}

extension NSObject: KeyValueObserving {}



