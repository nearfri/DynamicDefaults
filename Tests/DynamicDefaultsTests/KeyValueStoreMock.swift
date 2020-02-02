import Foundation
import DynamicDefaults

class KeyValueObservationMock: KeyValueObservation, Hashable {
    weak var store: KeyValueStoreMock?
    let key: String
    let handler: () -> Void
    
    init(store: KeyValueStoreMock, key: String, handler: @escaping () -> Void) {
        self.store = store
        self.key = key
        self.handler = handler
    }
    
    deinit {
        invalidate()
    }
    
    func invalidate() {
        store?.remove(self)
        store = nil
    }
    
    static func == (lhs: KeyValueObservationMock, rhs: KeyValueObservationMock) -> Bool {
        return lhs === rhs
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

class ObservationWrapper: KeyValueObservation {
    let observation: KeyValueObservationMock
    
    init(observation: KeyValueObservationMock) {
        self.observation = observation
    }
    
    deinit {
        invalidate()
    }
    
    func invalidate() {
        observation.invalidate()
    }
}

class KeyValueStoreMock: KeyValueStore {
    var valuesByKey: [String: Any] = [:]
    private var observationsByKey: [String: Set<KeyValueObservationMock>] = [:]
    
    func value(forKey key: String) -> Any? {
        return valuesByKey[key]
    }
    
    func setValue(_ value: Any, forKey key: String) {
        valuesByKey[key] = value
        
        for observation in observationsByKey[key] ?? [] {
            observation.handler()
        }
    }
    
    func removeValue(forKey key: String) {
        valuesByKey[key] = nil
        
        for observation in observationsByKey[key] ?? [] {
            observation.handler()
        }
    }
    
    func synchronize() -> Bool {
        return true
    }
    
    func observeValue(forKey key: String, handler: @escaping () -> Void) -> KeyValueObservation {
        let observation = KeyValueObservationMock(store: self, key: key, handler: handler)
        observationsByKey[key, default: []].insert(observation)
        return ObservationWrapper(observation: observation)
    }
    
    fileprivate func remove(_ observation: KeyValueObservationMock) {
        observationsByKey[observation.key]?.remove(observation)
    }
}
