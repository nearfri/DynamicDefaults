import XCTest
import CoreGraphics
@testable import Preferences

enum ColorType: String, Codable {
    case red
    case blue
    case green
    case black
    case white
    case yellow
}

enum Constant {
    static let creationDate: Date = Date(timeIntervalSince1970: 1547109206)
}

class Preferences: BasePreferences, Codable {
    static let `default`: Preferences = {
        return BasePreferences.instantiate(Preferences.self)
    }()
    
    var intNum: Int = 3 { didSet { store(intNum) } }
    
    var str: String = "hello" { didSet { store(str) } }
    
    var optIntNum1: Int? = 4 { didSet { store(optIntNum1) } }
    var optIntNum2: Int? = nil { didSet { store(optIntNum2) } }
    
    var color: ColorType = .blue { didSet { store(color) } }
    
    var doubleNum: Double = 5 { didSet { store(doubleNum) } }
    
    var rect: CGRect = CGRect(x: 1, y: 2, width: 3, height: 4) { didSet { store(rect) } }
    
    var colors: [ColorType] = [.blue, .black, .green] { didSet { store(colors) } }
    
    var creationDate: Date = Constant.creationDate { didSet { store(creationDate) } }
    
    var isItReal: Bool = false { didSet { store(isItReal) } }
}

class BasePreferencesTests: XCTestCase {
    var sut: Preferences!
    let userDefaults: UserDefaults = .standard
    
    override func setUp() {
        super.setUp()
        removeAllObjects(in: userDefaults)
        setupPreferences()
    }
    
    private func setupPreferences() {
        let dataContainer = LocalDataContainer(userDefaults: userDefaults)
        sut = BasePreferences.instantiate(Preferences.self, dataContainer: dataContainer)
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
        let defaultPref = Preferences()
        XCTAssertEqual(sut.intNum, defaultPref.intNum)
        XCTAssertEqual(sut.str, defaultPref.str)
        XCTAssertEqual(sut.optIntNum1, defaultPref.optIntNum1)
        XCTAssertEqual(sut.optIntNum2, defaultPref.optIntNum2)
        XCTAssertEqual(sut.color, defaultPref.color)
        XCTAssertEqual(sut.doubleNum, defaultPref.doubleNum)
        XCTAssertEqual(sut.rect, defaultPref.rect)
        XCTAssertEqual(sut.colors, defaultPref.colors)
        XCTAssertEqual(sut.creationDate, defaultPref.creationDate)
        XCTAssertEqual(sut.isItReal, defaultPref.isItReal)
    }
    
    func test_instantiate_onNextLaunch_hasChangedValues() {
        // Given
        let modifiedDate: Date = Date()
        
        sut.intNum = 7
        sut.str = "world"
        sut.optIntNum1 = nil
        sut.optIntNum2 = 5
        sut.color = .black
        sut.doubleNum = 9
        sut.rect = CGRect(x: 5, y: 6, width: 7, height: 8)
        sut.colors = [.yellow, .white, .red, .blue]
        sut.creationDate = modifiedDate
        sut.isItReal = true
        
        sut = nil
        
        // When
        setupPreferences()
        
        // Then
        XCTAssertEqual(sut.intNum, 7)
        XCTAssertEqual(sut.str, "world")
        XCTAssertEqual(sut.optIntNum1, nil)
        XCTAssertEqual(sut.optIntNum2, 5)
        XCTAssertEqual(sut.color, .black)
        XCTAssertEqual(sut.doubleNum, 9)
        XCTAssertEqual(sut.rect, CGRect(x: 5, y: 6, width: 7, height: 8))
        XCTAssertEqual(sut.colors, [.yellow, .white, .red, .blue])
        XCTAssertEqual(sut.creationDate, modifiedDate)
        XCTAssertEqual(sut.isItReal, true)
    }
}
