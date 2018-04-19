
import Foundation

open class BasePreferences3 {
    private(set) var userDefaults: UserDefaults = .standard
    
    public required init() {}
    
    static func instantiate<T: BasePreferences3>(
        _ type: T.Type, userDefaults: UserDefaults = .standard) throws -> T where T: Codable {
        
        // TODO: 인코딩 전에 마이그레이션 하기
        guard let defaultValues = try ObjectEncoder().encode(T.init()) as? [String: Any] else {
            preconditionFailure("Expected to encode \"\(type)\" as dictionary, but it was not.")
        }
        userDefaults.register(defaults: defaultValues)
        
        let storedValues = userDefaults.dictionaryRepresentation()
        let result = try ObjectDecoder().decode(type, from: storedValues)
        
        result.userDefaults = userDefaults
        
        return result
    }
    
    public func store<T: Encodable>(_ value: T?, forKey key: String = #function) {
        do {
            userDefaults.set(try encode(value), forKey: key)
        } catch {
            preconditionFailure("Failed to encode value for key \"\(key)\" -- \(error)")
        }
    }
    
    private func encode<T: Encodable>(_ value: T?) throws -> Any {
        guard let value = value else {
            return ObjectEncoder().nilSymbol
        }
        
        switch value {
        case is NSNumber, is String, is Data, is Date:
            return value
        default:
            return try ObjectEncoder().encode(value)
        }
    }
}

class MyPreferences: BasePreferences3, Codable {
    static let `default`: MyPreferences = try! BasePreferences3.instantiate(MyPreferences.self)
    
    var num: Int = 3 { didSet { store(num) } }
    
    var str: String = "hello" { didSet { store(str) } }
    
    var num2: Int? = 4 { didSet { store(num2) } }
    
    var color: ColorType = .blue { didSet { store(color) } }
    
    var num3: Double = 5 { didSet { store(num3) } }
    
    var rect: MyRect = .init(origin: .init(x: 1, y: 2), size: .init(width: 3, height: 4)) {
        didSet { store(rect) }
    }
}


struct MyPoint: Codable {
    var x: Float = 0
    var y: Float = 0
}

struct MySize: Codable {
    var width: Float = 0
    var height: Float = 0
}

struct MyRect: Codable {
    var origin: MyPoint = MyPoint(x: 0, y: 0)
    var size: MySize = MySize(width: 0, height: 0)
}



