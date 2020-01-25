# DynamicDefaults
[![SwiftPM](https://github.com/nearfri/DynamicDefaults/workflows/SwiftPM/badge.svg)](https://github.com/nearfri/DynamicDefaults/actions?query=workflow%3ASwiftPM)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

A Swift library to use UserDefaults in a easy way.

## Usage
```swift
import DynamicDefaults

enum ColorType: String, Codable {
    case red
    case blue
    case green
    case black
    case white
}

// 1. Define preferences model conforming to `Codable`.
struct PreferencesModel: Codable {
    var intNum: Int = 3
    var optIntNum: Int? = nil
    
    var str: String = "hello"
    var optStr: String? = "world"
    
    var rect: CGRect = CGRect(x: 1, y: 2, width: 3, height: 4)
    
    var colors: [ColorType] = [.blue, .black, .green]
    
    var creationDate: Date = Date(timeIntervalSinceReferenceDate: 0)
}

// 2. Define preferences class that inherits `UserDefaultsAccessor`.  
class Preferences: UserDefaultsAccessor<PreferencesModel> {
    let shared: Preferences = .init()
    
    init() {
        super.init(
            userDefaults: .standard,
            defaultSubject: PreferencesModel(),
            keysByKeyPath: [
                \PreferencesModel.intNum: "intNum",
                \PreferencesModel.optIntNum: "optIntNum",
                \PreferencesModel.str: "str",
                \PreferencesModel.optStr: "optStr",
                \PreferencesModel.rect: "rect",
                \PreferencesModel.colors: "colors",
                \PreferencesModel.creationDate: "creationDate",
            ]
        )
    }
}

// 3. Just use it.
let preferences = Preferences.shared

preferences.intNum = 5
XCTAssertEqual(preferences.intNum, 5)

preferences.rect.size = CGSize(width: 5, height: 6)
XCTAssertEqual(preferences.rect.size, CGSize(width: 5, height: 6))
```

## Install

#### Swift Package Manager
```
.package(url: "https://github.com/nearfri/DynamicDefaults", from: "1.0.0")
```

## License
Preferences is released under the MIT license. See [LICENSE](https://github.com/nearfri/DynamicDefaults/blob/master/LICENSE) for more information.



