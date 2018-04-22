
import XCTest
@testable import Defaults

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

extension MyRect {
    init(x: Float, y: Float, width: Float, height: Float) {
        origin.x = x
        origin.y = y
        size.width = width
        size.height = height
    }
}

class Animal: Codable, CustomStringConvertible {
    var name: String = ""
    var legCount: Int = 2
    var friends: [String] = []
    var fileURL: URL = URL(fileURLWithPath: "/path/to/file")
    
    var description: String {
        return "name: \(name), legCount: \(legCount), friends: \(friends), fileURL: \(fileURL)"
    }
}

class Dog: Animal {
    var frame: MyRect = MyRect(x: 0, y: 0, width: 10, height: 10)
    var age: Int = 0
    var stringURL: URL? = URL(string: "http://google.com")
    
    enum CodingKeys : CodingKey {
        case frame
        case age
        case stringURL
    }
    
    override init() {
        super.init()
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(frame, forKey: .frame)
        try container.encode(age, forKey: .age)
        if let url = stringURL {
            try container.encode(url, forKey: .stringURL)
        } else {
            try container.encodeNil(forKey: .stringURL)
        }
        try super.encode(to: container.superEncoder())
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        frame = try container.decode(MyRect.self, forKey: .frame)
        age = try container.decode(Int.self, forKey: .age)
        try super.init(from: container.superDecoder())
    }
    
    override var description: String {
        return super.description + ", frame: \(frame), age: \(age), stringURL: \(String(describing: stringURL))"
    }
}


class EncoderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let encoder = PropertyListEncoder2()
        
        let dog = Dog()
        dog.name = "Bow"
        dog.legCount = 4
        dog.frame = MyRect(x: 10, y: 20, width: 30, height: 40)
        dog.age = 5
        dog.friends = ["mike", "suzan"]
        
        let ret = try! encoder.encodeToTopLevelContainer(dog) as! [String: Any]
        print(ret)
    }
    
    func testMyEncoder() {
        let encoder = ObjectEncoder()
        
        let dog = Dog()
        dog.name = "Bow"
        dog.legCount = 4
        dog.frame = MyRect(x: 10, y: 20, width: 30, height: 40)
        dog.age = 5
        dog.friends = ["mike", "suzan"]
        
        let ret = try! encoder.encode(dog) as! [String: Any]
        print(ret)
        
        let decoder = ObjectDecoder()
        let dog2 = try! decoder.decodeValue(of: Dog.self, from: ret)
        print("dog1", dog)
        print("dog2", dog2)
    }
}
