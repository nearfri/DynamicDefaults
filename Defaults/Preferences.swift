
import Foundation

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
    @objc dynamic var dateValue: Date = Date()
    
    @objc private dynamic var urlString: String = "http://google.com"
    var urlValue: URL {
        get { return URL(string: urlString)! }
        set { urlString = newValue.absoluteString }
    }
    
    @objc private dynamic var fileURLString: String = "/path/to/file"
    var fileURLValue: URL {
        get { return URL(fileURLWithPath: fileURLString) }
        set { fileURLString = newValue.path }
    }
}



