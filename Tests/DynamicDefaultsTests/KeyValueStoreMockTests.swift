import XCTest
import DynamicDefaults

class KeyValueStoreMockTests: XCTestCase {
    var sut: KeyValueStoreMock!
    var observation: KeyValueObservation?
    
    override func setUp() {
        super.setUp()
        
        sut = KeyValueStoreMock()
    }
    
    override func tearDown() {
        super.tearDown()
        
        observation = nil
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
