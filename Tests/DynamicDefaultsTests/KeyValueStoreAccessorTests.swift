import XCTest
import CoreGraphics
import DynamicDefaults

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

struct PreferencesModel: Codable {
    var intNum: Int = 3
    var optIntNum1: Int? = 4
    var optIntNum2: Int? = nil
    
    var str: String = "hello"
    var optStr1: String? = "foo"
    var optStr2: String? = nil
    
    var color: ColorType = .blue
    
    var doubleNum: Double = 5
    
    var rect: CGRect = CGRect(x: 1, y: 2, width: 3, height: 4)
    
    var colors: [ColorType] = [.blue, .black, .green]
    
    var creationDate: Date = Constant.creationDate
    
    var isItReal: Bool = false
}

class Preferences: KeyValueStoreAccessor<PreferencesModel> {
    init(keyValueStore: KeyValueStoreMock) {
        super.init(
            keyValueStore: keyValueStore,
            defaultSubject: PreferencesModel(),
            keysByKeyPath: [ // 컴파일러의 도움을 받을 수 있다면 좋을텐데...
                \PreferencesModel.intNum: "intNum",
                \PreferencesModel.optIntNum1: "optIntNum1",
                \PreferencesModel.optIntNum2: "optIntNum2",
                \PreferencesModel.str: "str",
                \PreferencesModel.optStr1: "optStr1",
                \PreferencesModel.optStr2: "optStr2",
                \PreferencesModel.color: "color",
                \PreferencesModel.doubleNum: "doubleNum",
                \PreferencesModel.rect: "rect",
                \PreferencesModel.colors: "colors",
                \PreferencesModel.creationDate: "creationDate",
                \PreferencesModel.isItReal: "isItReal",
            ]
        )
    }
}

class KeyValueStoreAccessorTests: XCTestCase {
    private var sut: Preferences!
    private var keyValueStore: KeyValueStoreMock!
    
    override func setUp() {
        super.setUp()
        
        keyValueStore = KeyValueStoreMock()
        sut = Preferences(keyValueStore: keyValueStore)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_instantiate_onFirstLaunch_hasDefaultValues() {
        let model = PreferencesModel()
        XCTAssertEqual(sut.intNum, model.intNum)
        XCTAssertEqual(sut.optIntNum1, model.optIntNum1)
        XCTAssertEqual(sut.optIntNum2, model.optIntNum2)
        XCTAssertEqual(sut.str, model.str)
        XCTAssertEqual(sut.color, model.color)
        XCTAssertEqual(sut.doubleNum, model.doubleNum)
        XCTAssertEqual(sut.rect, model.rect)
        XCTAssertEqual(sut.colors, model.colors)
        XCTAssertEqual(sut.creationDate, model.creationDate)
        XCTAssertEqual(sut.isItReal, model.isItReal)
    }
    
    func test_instantiate_onNextLaunch_hasChangedValues() {
        // Given
        let modifiedDate: Date = Date()
        
        sut.intNum = 7
        sut.optIntNum1 = nil
        sut.optIntNum2 = 5
        sut.str = "world"
        sut.optStr1 = nil
        sut.optStr2 = "bar"
        sut.color = .black
        sut.doubleNum = 9
        sut.rect = CGRect(x: 5, y: 6, width: 7, height: 8)
        sut.rect.size.height += 2
        sut.colors = [.yellow, .white, .red, .blue]
        sut.creationDate = modifiedDate
        sut.isItReal = true
        
        sut = nil
        
        // When
        sut = Preferences(keyValueStore: keyValueStore)
        
        // Then
        XCTAssertEqual(sut.intNum, 7)
        XCTAssertEqual(sut.optIntNum1, nil)
        XCTAssertEqual(sut.optIntNum2, 5)
        XCTAssertEqual(sut.str, "world")
        XCTAssertEqual(sut.optStr1, nil)
        XCTAssertEqual(sut.optStr2, "bar")
        XCTAssertEqual(sut.color, .black)
        XCTAssertEqual(sut.doubleNum, 9)
        XCTAssertEqual(sut.rect, CGRect(x: 5, y: 6, width: 7, height: 10))
        XCTAssertEqual(sut.colors, [.yellow, .white, .red, .blue])
        XCTAssertEqual(sut.creationDate, modifiedDate)
        XCTAssertEqual(sut.isItReal, true)
    }
    
    func test_hasStoredValue_setValue_returnTrue() {
        // Given
        sut.color = .yellow
        
        // When
        let hasStoredValue = sut.hasStoredValue(for: \.color)
        
        // Then
        XCTAssert(hasStoredValue)
    }
    
    func test_hasStoredValue_notSetValue_returnFalse() {
        // Given
        
        // When
        let hasStoredValue = sut.hasStoredValue(for: \.color)
        
        // Then
        XCTAssertFalse(hasStoredValue)
    }
    
    func test_removeStoredValue() {
        // Given
        sut.color = .yellow
        
        // When
        sut.removeStoredValue(for: \.color)
        let hasStoredValue = sut.hasStoredValue(for: \.color)
        let color = sut.color
        
        // Then
        XCTAssertFalse(hasStoredValue)
        XCTAssertEqual(color, PreferencesModel().color)
    }
    
    func test_removeAllStoredValues() {
        // Given
        sut.color = .yellow
        sut.intNum = 7
        
        // When
        sut.removeAllStoredValues()
        let color = sut.color
        let intNum = sut.intNum
        
        // Then
        XCTAssertEqual(color, PreferencesModel().color)
        XCTAssertEqual(intNum, PreferencesModel().intNum)
    }
    
    func test_observe_setValue_callHandler() {
        // Given
        sut.color = .black
        
        // When
        var observedColor: ColorType?
        let observation = sut.observe(\.color) { color in
            observedColor = color
        }
        
        sut.color = .yellow
        
        // Then
        XCTAssertEqual(observedColor, .yellow)
        observation.invalidate()
    }
    
    func test_observe_invalidate_notCallHandler() {
        // Given
        sut.color = .black
        
        // When
        var observedColor: ColorType?
        let observation = sut.observe(\.color) { color in
            observedColor = color
        }
        observation.invalidate()
        
        sut.color = .yellow
        
        // Then
        XCTAssertNil(observedColor)
    }
}
