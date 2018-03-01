//
//  DefaultsTests.swift
//  DefaultsTests
//
//  Created by Ukjeong Lee on 2018. 3. 1..
//  Copyright © 2018년 Ukjeong Lee. All rights reserved.
//

import XCTest
@testable import Defaults

class DefaultsTests: XCTestCase {
    var pref: Preferences!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        removeAll()
        pref = Preferences()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func removeAll(userDefaults: UserDefaults = .standard) {
        for (key, _) in userDefaults.dictionaryRepresentation() {
            userDefaults.removeObject(forKey: key)
        }
    }
    
    func testNonOptionalValues() {
        checkInitialValues()
        
        pref.intValue = 5
        pref.doubleValue = 6
        pref.floatValue = 7
        pref.boolValue = false
        pref.stringValue = "world"
        pref.intArrayValue = [3, 4, 5, 6, 7, 8]
        pref.stringArrayValue = ["welcome", "home"]
        pref.dataValue = Data(count: 20)
        pref.dateValue = Date(timeIntervalSinceReferenceDate: 30)
        pref.urlValue = URL(string: "http://foo.bar")!
        pref.fileURLValue = URL(fileURLWithPath: "/path/to/seoul")
        pref.optStringValue = "wow"
        pref.optIntValue = 8
        pref.optStringValue = nil
        pref.optIntValue = nil
        pref.colorTypeValue = .yellow
        pref.subInfo.number = 12
        pref.subInfo.title = "track"
        
        pref = Preferences()
        XCTAssertEqual(pref.intValue, 5)
        XCTAssertEqual(pref.doubleValue, 6)
        XCTAssertEqual(pref.floatValue, 7)
        XCTAssertEqual(pref.boolValue, false)
        XCTAssertEqual(pref.stringValue, "world")
        XCTAssertEqual(pref.intArrayValue, [3, 4, 5, 6, 7, 8])
        XCTAssertEqual(pref.stringArrayValue, ["welcome", "home"])
        XCTAssertEqual(pref.dataValue, Data(count: 20))
        XCTAssertEqual(pref.dateValue, Date(timeIntervalSinceReferenceDate: 30))
        XCTAssertEqual(pref.urlValue, URL(string: "http://foo.bar"))
        XCTAssertEqual(pref.fileURLValue, URL(fileURLWithPath: "/path/to/seoul"))
//        XCTAssertEqual(pref.optStringValue, "wow")
//        XCTAssertEqual(pref.optIntValue, 8)
        XCTAssertNil(pref.optStringValue)
        XCTAssertNil(pref.optIntValue)
        XCTAssertEqual(pref.colorTypeValue, .yellow)
        XCTAssertEqual(pref.subInfo.number, 12)
        XCTAssertEqual(pref.subInfo.title, "track")
        
        removeAll()
        pref = Preferences()
        
        checkInitialValues()
    }
    
    func checkInitialValues() {
        XCTAssertEqual(pref.intValue, 3)
        XCTAssertEqual(pref.doubleValue, 4)
        XCTAssertEqual(pref.floatValue, 5)
        XCTAssertEqual(pref.boolValue, true)
        XCTAssertEqual(pref.stringValue, "hello")
        XCTAssertEqual(pref.intArrayValue, [1, 2, 3, 4, 5])
        XCTAssertEqual(pref.stringArrayValue, ["hello", "world"])
        XCTAssertEqual(pref.dataValue, Data(count: 10))
        XCTAssertEqual(pref.dateValue, Date(timeIntervalSinceReferenceDate: 20))
        XCTAssertEqual(pref.urlValue, URL(string: "http://google.com"))
        XCTAssertEqual(pref.fileURLValue, URL(fileURLWithPath: "/path/to/file"))
        XCTAssertNil(pref.optStringValue)
        XCTAssertNil(pref.optIntValue)
        XCTAssertEqual(pref.colorTypeValue, ColorType.blue)
        XCTAssertEqual(pref.subInfo.number, 8)
        XCTAssertEqual(pref.subInfo.title, "magnet")
    }
}
