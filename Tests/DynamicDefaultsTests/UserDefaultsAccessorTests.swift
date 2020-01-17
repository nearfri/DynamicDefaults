import XCTest
import CoreGraphics
@testable import DynamicDefaults

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

struct SettingsModel: Codable {
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

typealias Settings = UserDefaultsAccessor<SettingsModel>

extension Settings {
    static func instantiate() -> Settings {
        return Settings(
            userDefaults: .standard,
            defaultSubject: SettingsModel(),
            keysByKeyPath: [ // 컴파일러의 도움을 받을 수 있다면 좋을텐데...
                \SettingsModel.intNum: "intNum",
                \SettingsModel.optIntNum1: "optIntNum1",
                \SettingsModel.optIntNum2: "optIntNum2",
                \SettingsModel.str: "str",
                \SettingsModel.optStr1: "optStr1",
                \SettingsModel.optStr2: "optStr2",
                \SettingsModel.color: "color",
                \SettingsModel.doubleNum: "doubleNum",
                \SettingsModel.rect: "rect",
                \SettingsModel.colors: "colors",
                \SettingsModel.creationDate: "creationDate",
                \SettingsModel.isItReal: "isItReal",
            ]
        )
    }
}

class UserDefaultsAccessorTests: XCTestCase {
    private var sut: Settings!
    
    override func setUp() {
        super.setUp()
        removeAllObjects(in: .standard)
        sut = Settings.instantiate()
    }
    
    private func removeAllObjects(in userDefaults: UserDefaults) {
        for (key, _) in userDefaults.dictionaryRepresentation() {
            userDefaults.removeObject(forKey: key)
        }
    }
    
    override func tearDown() {
        super.tearDown()
        removeAllObjects(in: .standard)
    }
    
    func test_instantiate_onFirstLaunch_hasDefaultValues() {
        let model = SettingsModel()
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
        sut.colors = [.yellow, .white, .red, .blue]
        sut.creationDate = modifiedDate
        sut.isItReal = true
        
        sut = nil
        
        // When
        sut = Settings.instantiate()
        
        // Then
        XCTAssertEqual(sut.intNum, 7)
        XCTAssertEqual(sut.optIntNum1, nil)
        XCTAssertEqual(sut.optIntNum2, 5)
        XCTAssertEqual(sut.str, "world")
        XCTAssertEqual(sut.optStr1, nil)
        XCTAssertEqual(sut.optStr2, "bar")
        XCTAssertEqual(sut.color, .black)
        XCTAssertEqual(sut.doubleNum, 9)
        XCTAssertEqual(sut.rect, CGRect(x: 5, y: 6, width: 7, height: 8))
        XCTAssertEqual(sut.colors, [.yellow, .white, .red, .blue])
        XCTAssertEqual(sut.creationDate, modifiedDate)
        XCTAssertEqual(sut.isItReal, true)
    }
}
