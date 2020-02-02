import XCTest
import DynamicDefaults

class SharedKeyValueStoreTests: XCTestCase {
    var sut: SharedKeyValueStore!
    var observation: KeyValueObservation?
    
    override func setUp() {
        super.setUp()
        
        sut = SharedKeyValueStore(store: .default)
    }
    
    override func tearDown() {
        super.tearDown()
        
        removeAllObjects(in: .default)
        observation = nil
    }
    
    private func removeAllObjects(in store: NSUbiquitousKeyValueStore) {
        for (key, _) in store.dictionaryRepresentation {
            store.removeObject(forKey: key)
        }
    }
    
    func test_observeValue_setValue_callHandler() {
        // Given
        let key = "magicNumber"
        var handlerCalled = false
        
        observation = sut.observeValue(forKey: key) {
            handlerCalled = true
        }
        
        // When
        sut.setValue(7, forKey: key)
        
        // Then
        XCTAssert(handlerCalled)
    }
    
    func test_observeValue_setOtherValue_notCallHandler() {
        // Given
        let key = "magicNumber"
        var handlerCalled = false
        
        observation = sut.observeValue(forKey: key) {
            handlerCalled = true
        }
        
        // When
        sut.setValue(7, forKey: key + "2")
        
        // Then
        XCTAssertFalse(handlerCalled)
    }
    
    func test_observeValue_invalidate_notCallHandler() {
        // Given
        let key = "magicNumber"
        var handlerCalled = false
        
        observation = sut.observeValue(forKey: key) {
            handlerCalled = true
        }
        observation = nil
        
        // When
        sut.setValue(7, forKey: key)
        
        // Then
        XCTAssertFalse(handlerCalled)
    }
}
