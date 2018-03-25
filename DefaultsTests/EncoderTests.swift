//
//  EncoderTests.swift
//  DefaultsTests
//
//  Created by Ukjeong Lee on 2018. 3. 24..
//  Copyright © 2018년 Ukjeong Lee. All rights reserved.
//

import XCTest
@testable import Defaults

class Animal: Codable {
    var name: String = ""
    var legCount: Int = 2
}

class Dog: Animal {
    var frame: CGRect = CGRect(x: 0, y: 0, width: 10, height: 10)
    var age: Int = 0
    
    enum CodingKeys : CodingKey {
        case frame
        case age
    }
    
    override init() {
        super.init()
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(frame, forKey: .frame)
        try container.encode(age, forKey: .age)
        try super.encode(to: container.superEncoder())
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        frame = try container.decode(CGRect.self, forKey: .frame)
        age = try container.decode(Int.self, forKey: .age)
        try super.init(from: container.superDecoder())
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
        dog.frame = CGRect(x: 10, y: 20, width: 30, height: 40)
        dog.age = 5
        
        let ret = try! encoder.encodeToTopLevelContainer(dog) as! [String: Any]
        print(ret)
    }
}
