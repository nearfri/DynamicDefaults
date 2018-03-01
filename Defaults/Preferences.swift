
import Foundation

enum ColorType: Int {
    case red
    case blue
    case green
    case black
    case white
    case yellow
}

class SubInfo: NSObject, SubPreferences {
    @objc dynamic var number: Int = 8
    @objc dynamic var title: String = "magnet"
}

class Preferences: BasePreferences {
    static let shared: Preferences = Preferences()
    
    @objc dynamic var intValue: Int = 3
    @objc dynamic var doubleValue: Double = 4
    @objc dynamic var floatValue: Float = 5
    @objc dynamic var boolValue: Bool = true
    @objc dynamic var stringValue: String = "hello"
    @objc dynamic var intArrayValue: [Int] = [1, 2, 3, 4, 5]
    @objc dynamic var stringArrayValue: [String] = ["hello", "world"]
    @objc dynamic var dataValue: Data = Data(count: 10)
    @objc dynamic var dateValue: Date = Date(timeIntervalSinceReferenceDate: 20)
    
    var urlValue: URL {
        get { return URL(string: rawURLValue)! }
        set { rawURLValue = newValue.absoluteString }
    }
    @objc private dynamic var rawURLValue: String = "http://google.com"
    
    var fileURLValue: URL {
        get { return URL(fileURLWithPath: rawFileURLValue) }
        set { rawFileURLValue = newValue.path }
    }
    @objc private dynamic var rawFileURLValue: String = "/path/to/file"
    
    @objc dynamic var optStringValue: String? = nil
    
    var optIntValue: Int? {
        get { return rawOptIntValue?.intValue }
        set { rawOptIntValue = newValue.map({ NSNumber(value: $0) }) }
    }
    @objc private dynamic var rawOptIntValue: NSNumber? = nil
    
    var colorTypeValue: ColorType {
        get { return ColorType(rawValue: rawColorTypeValue)! }
        set { rawColorTypeValue = newValue.rawValue }
    }
    @objc private dynamic var rawColorTypeValue: Int = ColorType.blue.rawValue
    
    @objc dynamic var subInfo: SubInfo = SubInfo()
    
    override func migrateUserDefaults(_ userDefaults: UserDefaults) {
        migrateValueForKeyPath(from: "oldIntValue", to: #keyPath(intValue))
    }
}



