import XCTest
import CoreGraphics
@testable import DynamicDefaults

class ObservablePreferences: BasePreferences, Codable {
    static let `default`: ObservablePreferences = {
        return BasePreferences.instantiate(ObservablePreferences.self)
    }()
    
    private let channels: Channels = Channels()
    
    private func store<T>(_ keyPath: KeyPath<ObservablePreferences, T>,
                          forKey key: String = #function) where T : Encodable {
        store(self[keyPath: keyPath], forKey: key)
        channels[keyPath]?.broadcast(self)
    }
    
    func channel<T>(for keyPath: KeyPath<ObservablePreferences, T>
        ) -> Channel<ObservablePreferences> {
        
        if let result = channels[keyPath] {
            return result
        }
        let result = Channel<ObservablePreferences>()
        channels[keyPath] = result
        return result
    }
    
    var num: Int = 3 { didSet { store(\.num) } }
    
    var str: String = "hello" { didSet { store(\.str) } }
    
    var rect: CGRect = CGRect(x: 1, y: 2, width: 3, height: 4) { didSet { store(\.rect) } }
}

extension ObservablePreferences {
    private class Channels: Codable {
        var storage: [PartialKeyPath<ObservablePreferences>: Channel<ObservablePreferences>] = [:]
        
        init() {}
        
        required init(from decoder: Decoder) throws {}
        
        func encode(to encoder: Encoder) throws {}
        
        subscript(keyPath: PartialKeyPath<ObservablePreferences>
            ) -> Channel<ObservablePreferences>? {
            
            get { return storage[keyPath] }
            set { storage[keyPath] = newValue }
        }
    }
}

class ObservablePreferencesTests: XCTestCase {
    var sut: ObservablePreferences!
    let userDefaults: UserDefaults = .standard
    
    override func setUp() {
        super.setUp()
        removeAllObjects(in: userDefaults)
        setupPreferences()
    }
    
    private func setupPreferences() {
        let dataContainer = LocalDataContainer(userDefaults: userDefaults)
        sut = BasePreferences.instantiate(ObservablePreferences.self, dataContainer: dataContainer)
    }
    
    override func tearDown() {
        super.tearDown()
        removeAllObjects(in: userDefaults)
    }
    
    private func removeAllObjects(in userDefaults: UserDefaults) {
        for (key, _) in userDefaults.dictionaryRepresentation() {
            userDefaults.removeObject(forKey: key)
        }
    }
    
    func test_instantiate_onFirstLaunch_hasDefaultValues() {
        let defaultPref = ObservablePreferences()
        XCTAssertEqual(sut.num, defaultPref.num)
        XCTAssertEqual(sut.str, defaultPref.str)
        XCTAssertEqual(sut.rect, defaultPref.rect)
    }
    
    func test_instantiate_onNextLaunch_hasChangedValues() {
        // Given
        sut.num = 7
        sut.str = "world"
        sut.rect = CGRect(x: 5, y: 6, width: 7, height: 8)
        
        sut = nil
        
        // When
        setupPreferences()
        
        // Then
        XCTAssertEqual(sut.num, 7)
        XCTAssertEqual(sut.str, "world")
        XCTAssertEqual(sut.rect, CGRect(x: 5, y: 6, width: 7, height: 8))
    }
    
    func test_observation_onChangeValue_notify() {
        // Given
        var numNotified = false
        var strNotified = false
        var rectNotified = false
        
        sut.channel(for: \.num).addSubscriber(self) { (pref) in
            numNotified = true
        }
        sut.channel(for: \.str).addSubscriber(self) { (pref) in
            strNotified = true
        }
        sut.channel(for: \.rect).addSubscriber(self) { (pref) in
            rectNotified = true
        }
        
        // When
        sut.num = 9
        
        // Then
        XCTAssertTrue(numNotified)
        XCTAssertFalse(strNotified)
        XCTAssertFalse(rectNotified)
    }
}
