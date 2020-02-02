import XCTest
import DynamicDefaults

class AppKeyValueStoreTests: XCTestCase {
    var sut: AppKeyValueStore!
    var observation: KeyValueObservation?
    
    override func setUp() {
        super.setUp()
        
        sut = AppKeyValueStore(defaults: .standard)
    }
    
    override func tearDown() {
        super.tearDown()
        
        removeAllObjects(in: .standard)
        observation = nil
    }
    
    private func removeAllObjects(in userDefaults: UserDefaults) {
        for (key, _) in userDefaults.dictionaryRepresentation() {
            userDefaults.removeObject(forKey: key)
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
