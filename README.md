# Preferences [![Build Status](https://travis-ci.org/nearfri/Preferences.svg?branch=master)](https://travis-ci.org/nearfri/Preferences)
A Swift library to use UserDefaults in a easy way.

## Usage

### 1. Declare your `Preferences` with `Codable` value type properties
```swift
enum ColorType: String, Codable {
    case red
    case blue
    case green
    case black
    case white
}

class Preferences: BasePreferences, Codable {
    static let `default`: Preferences = {
        return BasePreferences.instantiate(Preferences.self)
    }()
    
    var intNum: Int = 3 { didSet { store(intNum) } }
    
    var optIntNum: Int? = nil { didSet { store(optIntNum) } }
    
    var str: String = "hello" { didSet { store(str) } }
    
    var color: ColorType = .blue { didSet { store(color) } }
    
    var rect: CGRect = CGRect(x: 1, y: 2, width: 3, height: 4) { didSet { store(rect) } }
    
    var colors: [ColorType] = [.blue, .black, .green] { didSet { store(colors) } }
    
    var creationDate: Date = Date() { didSet { store(creationDate) } }
    
    var isItReal: Bool = false { didSet { store(isItReal) } }
}

```

### 2. Create and use
```swift
let pref = Preferences.default
pref.intNum // 3
pref.intNum += 1 // 4
UserDefaults.standard.integer(forKey: "intNum") // 4
```

### If you want to observe changes
See [this example](https://github.com/nearfri/Preferences/blob/master/Tests/ObservablePreferencesTests.swift).

## Install

#### Carthage
```
github "nearfri/Preferences"
```

#### Swift Package Manager
```
.package(url: "https://github.com/nearfri/Preferences", from: "1.0.0")
```

## License
Preferences is released under the MIT license. See [LICENSE](https://github.com/nearfri/Preferences/blob/master/LICENSE) for more information.



