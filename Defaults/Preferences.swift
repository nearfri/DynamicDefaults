
import Foundation
import CoreGraphics

enum ColorType: String, Codable {
    case red
    case blue
    case green
    case black
    case white
    case yellow
}

class Preferences: BasePreferences, Codable {
    static let `default`: Preferences = {
        let userDefaults = UserDefaults(suiteName: "AppPreferences")!
        return try! BasePreferences.instantiate(Preferences.self, userDefaults: userDefaults)
    }()
    
    var num: Int = 3 { didSet { store(num) } }
    
    var str: String = "hello" { didSet { store(str) } }
    
    var num2: Int? = 4 { didSet { store(num2) } }
    
    var color: ColorType = .blue { didSet { store(color) } }
    
    var num3: Double = 5 { didSet { store(num3) } }
    
    var rect: CGRect = CGRect(x: 1, y: 2, width: 3, height: 4) { didSet { store(rect) } }
    
    var colors: [ColorType] = [.blue, .black, .green] { didSet { store(colors) } }
    
    var creationDate: Date = Date() { didSet { store(creationDate) } }
    
    var isItReal: Bool = false { didSet { store(isItReal) } }
}



