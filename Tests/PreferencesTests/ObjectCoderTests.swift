import XCTest
@testable import Preferences

// ref.: https://github.com/apple/swift/blob/master/test/stdlib/TestPlistEncoder.swift

class ObjectCoderTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Encoding Top-Level Empty Types
    
    func testEncodingTopLevelEmptyStruct() {
        let empty = EmptyStruct()
        testRoundTrip(of: empty, expectedEncodedValue: emptyDictionary)
    }
    
    private struct EmptyStruct: Codable, Equatable {}
    
    private var emptyDictionary: [String: String] {
        return [:]
    }
    
    private func testRoundTrip<T, U>(
        of value: T,
        expectedEncodedValue: U,
        nilEncodingStrategy: NilEncodingStrategy? = nil,
        nilDecodingStrategy: NilDecodingStrategy? = nil,
        file: StaticString = #file,
        line: UInt = #line) where T: Codable, T: Equatable, U: Equatable {
        
        let encodedValue: Any
        do {
            let encoder = ObjectEncoder()
            if let nilStrategy = nilEncodingStrategy {
                encoder.nilEncodingStrategy = nilStrategy
            }
            encodedValue = try encoder.encode(value)
        } catch {
            XCTFail("Failed to encode \(T.self): \(error)", file: file, line: line)
            return
        }
        
        if let encodedValue = encodedValue as? U {
            XCTAssertEqual(encodedValue, expectedEncodedValue,
                           "Encoded value is not identical to expected value.",
                           file: file, line: line)
        } else {
            XCTFail("""
                ("\(String(describing: encodedValue))") is not equal to \
                ("\(expectedEncodedValue)") - Encoded value is not identical to expected value.
                """, file: file, line: line)
        }
        
        do {
            let decoder = ObjectDecoder()
            if let nilStrategy = nilDecodingStrategy {
                decoder.nilDecodingStrategy = nilStrategy
            }
            let decodedValue = try decoder.decode(T.self, from: encodedValue)
            XCTAssertEqual(decodedValue, value, "\(T.self) did not round-trip to an equal value.",
                file: file, line: line)
        } catch {
            XCTFail("Failed to decode \(T.self): \(error)", file: file, line: line)
        }
    }
    
    func testEncodingTopLevelEmptyClass() {
        let empty = EmptyClass()
        testRoundTrip(of: empty, expectedEncodedValue: emptyDictionary)
    }
    
    private class EmptyClass: Codable, Equatable {
        static func == (_ lhs: EmptyClass, _ rhs: EmptyClass) -> Bool {
            return true
        }
    }
    
    // MARK: - Encoding Top-Level Standard Types
    
    func testEncodingTopLevelBool() {
        testRoundTrip(of: true, expectedEncodedValue: true)
        testRoundTrip(of: false, expectedEncodedValue: false)
    }
    
    func testEncodingTopLevelInteger() {
        testFixedWidthInteger(type: Int.self)
        testFixedWidthInteger(type: Int8.self)
        testFixedWidthInteger(type: Int16.self)
        testFixedWidthInteger(type: Int32.self)
        testFixedWidthInteger(type: Int64.self)
        testFixedWidthInteger(type: UInt.self)
        testFixedWidthInteger(type: UInt8.self)
        testFixedWidthInteger(type: UInt16.self)
        testFixedWidthInteger(type: UInt32.self)
        testFixedWidthInteger(type: UInt64.self)
    }
    
    private func testFixedWidthInteger<T>(
        type: T.Type, file: StaticString = #file, line: UInt = #line
        ) where T: FixedWidthInteger & Codable {
        
        testRoundTrip(of: type.min, expectedEncodedValue: type.min, file: file, line: line)
        testRoundTrip(of: type.max, expectedEncodedValue: type.max, file: file, line: line)
    }
    
    func testEncodingTopLevelFloatingPoint() {
        testFloatingPoint(type: Float.self)
        testFloatingPoint(type: Double.self)
    }
    
    private func testFloatingPoint<T>(
        type: T.Type, file: StaticString = #file, line: UInt = #line
        ) where T: FloatingPoint & Codable {
        
        testRoundTrip(of: type.leastNormalMagnitude,
                      expectedEncodedValue: type.leastNormalMagnitude,
                      file: file, line: line)
        testRoundTrip(of: type.greatestFiniteMagnitude,
                      expectedEncodedValue: type.greatestFiniteMagnitude,
                      file: file, line: line)
        testRoundTrip(of: type.infinity,
                      expectedEncodedValue: type.infinity,
                      file: file, line: line)
    }
    
    func testEncodingTopLevelString() {
        let string = "Hello Encoder"
        testRoundTrip(of: string, expectedEncodedValue: string)
    }
    
    func testEncodingTopLevelNil() {
        let nilValue: Int? = nil
        let nilSymbol = NilEncodingStrategy.defaultNilSymbol
        testRoundTrip(of: nilValue, expectedEncodedValue: nilSymbol)
    }
    
    func testEncodingTopLevelURL() {
        let url = URL(string: "https://apple.com")!
        testRoundTrip(of: url, expectedEncodedValue: ["relative": "https://apple.com"])
    }
    
    func testEncodingTopLevelData() {
        let data = Data([0xAB, 0xDE, 0xF3, 0x05])
        testRoundTrip(of: data, expectedEncodedValue: data)
    }
    
    func testEncodingTopLevelDate() {
        let date = Date()
        testRoundTrip(of: date, expectedEncodedValue: date)
    }
    
    // MARK: - Encoding Top-Level Single-Value Types
    
    func testEncodingTopLevelSingleValueEnum() {
        let s1 = Switch.off
        testRoundTrip(of: s1, expectedEncodedValue: false)
        
        let s2 = Switch.on
        testRoundTrip(of: s2, expectedEncodedValue: true)
    }
    
    /// A simple on-off switch type that encodes as a single Bool value.
    private enum Switch: Codable {
        case off
        case on
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            switch try container.decode(Bool.self) {
            case false: self = .off
            case true:  self = .on
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .off: try container.encode(false)
            case .on:  try container.encode(true)
            }
        }
    }
    
    func testEncodingTopLevelSingleValueStruct() {
        let value: Double = 3141592653
        let timestamp = Timestamp(value)
        testRoundTrip(of: timestamp, expectedEncodedValue: value)
    }
    
    /// A simple timestamp type that encodes as a single Double value.
    private struct Timestamp: Codable, Equatable {
        let value: Double
        
        init(_ value: Double) {
            self.value = value
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            value = try container.decode(Double.self)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.value)
        }
    }
    
    func testEncodingTopLevelSingleValueClass() {
        let count = 5
        let counter = Counter(count)
        testRoundTrip(of: counter, expectedEncodedValue: count)
    }
    
    /// A simple referential counter type that encodes as a single Int value.
    private final class Counter: Codable, Equatable {
        var count: Int = 0
        
        init(_ count: Int) {
            self.count = count
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            count = try container.decode(Int.self)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.count)
        }
        
        static func == (_ lhs: Counter, _ rhs: Counter) -> Bool {
            return lhs === rhs || lhs.count == rhs.count
        }
    }
    
    // MARK: - Encoding Top-Level Structured Types
    
    func testEncodingTopLevelKeyedRawValueStruct() {
        let keyedStruct = KeyedRawValueStruct.testValue
        testRoundTrip(of: keyedStruct)
    }
    
    private struct KeyedRawValueStruct: Codable, Equatable {
        let bool: Bool
        let int: Int
        let int8: Int8
        let int16: Int16
        let int32: Int32
        let int64: Int64
        let uint: UInt
        let uint8: UInt8
        let uint16: UInt16
        let uint32: UInt32
        let uint64: UInt64
        let float: Float
        let double: Double
        let string: String
        let strings: [String]
        let optionalString: String?
        let optionalStrings: [String?]
        
        static var testValue: KeyedRawValueStruct {
            return KeyedRawValueStruct(
                bool: true, int: .max, int8: .max, int16: .max, int32: .max, int64: .max,
                uint: .max, uint8: .max, uint16: .max, uint32: .max, uint64: .max,
                float: .greatestFiniteMagnitude, double: .greatestFiniteMagnitude,
                string: "Hello world", strings: ["Friday", "Saturday", "Sunday"],
                optionalString: nil, optionalStrings: ["Monday", nil, "Wednesday"]
            )
        }
    }
    
    private func testRoundTrip<T>(
        of value: T,
        file: StaticString = #file,
        line: UInt = #line) where T: Codable, T: Equatable {
        
        let encodedValue: Any
        do {
            let encoder = ObjectEncoder()
            encodedValue = try encoder.encode(value)
        } catch {
            XCTFail("Failed to encode \(T.self): \(error)", file: file, line: line)
            return
        }
        
        do {
            let decoder = ObjectDecoder()
            let decodedValue = try decoder.decode(T.self, from: encodedValue)
            XCTAssertEqual(decodedValue, value, "\(T.self) did not round-trip to an equal value.",
                file: file, line: line)
        } catch {
            XCTFail("Failed to decode \(T.self): \(error)", file: file, line: line)
        }
    }
    
    func testEncodingTopLevelUnkeyedRawValueStruct() {
        let unkeyedStruct = UnkeyedRawValueStruct.testValue
        testRoundTrip(of: unkeyedStruct)
    }
    
    private struct UnkeyedRawValueStruct: Codable, Equatable {
        let bool: Bool
        let int: Int
        let int8: Int8
        let int16: Int16
        let int32: Int32
        let int64: Int64
        let uint: UInt
        let uint8: UInt8
        let uint16: UInt16
        let uint32: UInt32
        let uint64: UInt64
        let float: Float
        let double: Double
        let string: String
        let strings: [String]
        let optionalString: String?
        let optionalStrings: [String?]
        
        init(bool: Bool, int: Int, int8: Int8, int16: Int16, int32: Int32, int64: Int64,
             uint: UInt, uint8: UInt8, uint16: UInt16, uint32: UInt32, uint64: UInt64,
             float: Float, double: Double, string: String, strings: [String],
             optionalString: String?, optionalStrings: [String?]) {
            
            self.bool = bool
            self.int = int
            self.int8 = int8
            self.int16 = int16
            self.int32 = int32
            self.int64 = int64
            self.uint = uint
            self.uint8 = uint8
            self.uint16 = uint16
            self.uint32 = uint32
            self.uint64 = uint64
            self.float = float
            self.double = double
            self.string = string
            self.strings = strings
            self.optionalString = optionalString
            self.optionalStrings = optionalStrings
        }
        
        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            bool = try container.decode(Bool.self)
            int = try container.decode(Int.self)
            int8 = try container.decode(Int8.self)
            int16 = try container.decode(Int16.self)
            int32 = try container.decode(Int32.self)
            int64 = try container.decode(Int64.self)
            uint = try container.decode(UInt.self)
            uint8 = try container.decode(UInt8.self)
            uint16 = try container.decode(UInt16.self)
            uint32 = try container.decode(UInt32.self)
            uint64 = try container.decode(UInt64.self)
            float = try container.decode(Float.self)
            double = try container.decode(Double.self)
            string = try container.decode(String.self)
            strings = try container.decode([String].self)
            
            // Optional인 경우 container.decodeIfPresent()를 호출하는게 정석이지만
            // 이렇게 그냥 decode()를 호출하는 경우도 정상적으로 처리해야 한다.
            optionalString = try container.decode(String?.self)
            
            optionalStrings = try container.decode([String?].self)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(bool)
            try container.encode(int)
            try container.encode(int8)
            try container.encode(int16)
            try container.encode(int32)
            try container.encode(int64)
            try container.encode(uint)
            try container.encode(uint8)
            try container.encode(uint16)
            try container.encode(uint32)
            try container.encode(uint64)
            try container.encode(float)
            try container.encode(double)
            try container.encode(string)
            try container.encode(strings)
            try container.encode(optionalString)
            try container.encode(optionalStrings)
        }
        
        static var testValue: UnkeyedRawValueStruct {
            return UnkeyedRawValueStruct(
                bool: true, int: .max, int8: .max, int16: .max, int32: .max, int64: .max,
                uint: .max, uint8: .max, uint16: .max, uint32: .max, uint64: .max,
                float: .greatestFiniteMagnitude, double: .greatestFiniteMagnitude,
                string: "Hello world", strings: ["Saturday", "Sunday"],
                optionalString: nil, optionalStrings: ["Monday", nil, "Wednesday"]
            )
        }
    }
    
    func testEncodingTopLevelStructuredStruct() {
        let address = Address.testValue
        testRoundTrip(of: address)
    }
    
    /// A simple address type that encodes as a dictionary of values.
    private struct Address: Codable, Equatable {
        let street: String
        let city: String
        let state: String
        let zipCode: Int
        let country: String
        
        init(street: String, city: String, state: String, zipCode: Int, country: String) {
            self.street = street
            self.city = city
            self.state = state
            self.zipCode = zipCode
            self.country = country
        }
        
        static var testValue: Address {
            return Address(street: "1 Infinite Loop",
                           city: "Cupertino",
                           state: "CA",
                           zipCode: 95014,
                           country: "United States")
        }
    }
    
    func testEncodingTopLevelStructuredClass() {
        let person = Person.testValue
        testRoundTrip(of: person)
    }
    
    /// A simple person class that encodes as a dictionary of values.
    private class Person: Codable, Equatable {
        let name: String
        let email: String
        let website: URL?
        
        init(name: String, email: String, website: URL? = nil) {
            self.name = name
            self.email = email
            self.website = website
        }
        
        func isEqual(to other: Person) -> Bool {
            return self.name == other.name &&
                self.email == other.email &&
                self.website == other.website
        }
        
        static func == (_ lhs: Person, _ rhs: Person) -> Bool {
            return lhs.isEqual(to: rhs)
        }
        
        class var testValue: Person {
            return Person(name: "Johnny Appleseed", email: "appleseed@apple.com")
        }
    }
    
    func testEncodingTopLevelStructuredSingleStruct() {
        let numbers = Numbers.testValue
        testRoundTrip(of: numbers)
    }
    
    /// A type which encodes as an array directly through a single value container.
    private struct Numbers: Codable, Equatable {
        let values = [4, 8, 15, 16, 23, 42]
        
        init() {}
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let decodedValues = try container.decode([Int].self)
            guard decodedValues == values else {
                let errorContext = DecodingError.Context(codingPath: decoder.codingPath,
                                                         debugDescription: "The Numbers are wrong!")
                throw DecodingError.dataCorrupted(errorContext)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(values)
        }
        
        static var testValue: Numbers {
            return Numbers()
        }
    }
    
    func testEncodingTopLevelStructuredSingleClass() {
        let mapping = Mapping.testValue
        testRoundTrip(of: mapping)
    }
    
    /// A type which encodes as a dictionary directly through a single value container.
    private final class Mapping: Codable, Equatable {
        let values: [String: URL]
        
        init(values: [String: URL]) {
            self.values = values
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            values = try container.decode([String: URL].self)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(values)
        }
        
        static func == (_ lhs: Mapping, _ rhs: Mapping) -> Bool {
            return lhs === rhs || lhs.values == rhs.values
        }
        
        static var testValue: Mapping {
            return Mapping(values: ["Apple": URL(string: "http://apple.com")!,
                                    "localhost": URL(string: "http://127.0.0.1")!])
        }
    }
    
    func testEncodingClassWhichSharesEncoderWithSuper() {
        let employee = Employee.testValue
        testRoundTrip(of: employee)
    }
    
    /// A class which shares its encoder and decoder with its superclass.
    private class Employee: Person {
        let id: Int
        
        init(name: String, email: String, website: URL? = nil, id: Int) {
            self.id = id
            super.init(name: name, email: email, website: website)
        }
        
        enum CodingKeys: String, CodingKey {
            case id
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(Int.self, forKey: .id)
            try super.init(from: decoder)
        }
        
        override func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try super.encode(to: encoder)
        }
        
        override func isEqual(to other: Person) -> Bool {
            if let employee = other as? Employee {
                guard self.id == employee.id else { return false }
            }
            
            return super.isEqual(to: other)
        }
        
        override class var testValue: Employee {
            return Employee(name: "Johnny Appleseed", email: "appleseed@apple.com", id: 42)
        }
    }
    
    func testEncodingTopLevelDeepStructuredType() {
        let company = Company.testValue
        testRoundTrip(of: company)
    }
    
    /// A simple company struct which encodes as a dictionary of nested values.
    private struct Company: Codable, Equatable {
        let address: Address
        var employees: [Employee]
        
        init(address: Address, employees: [Employee]) {
            self.address = address
            self.employees = employees
        }
        
        static var testValue: Company {
            return Company(address: Address.testValue, employees: [Employee.testValue])
        }
    }
    
    func testEncodingTopLevelNullableType() {
        testRoundTrip(of: EnhancedBool.true, expectedEncodedValue: true)
        testRoundTrip(of: EnhancedBool.false, expectedEncodedValue: false)
        testRoundTrip(of: EnhancedBool.fileNotFound)
    }
    
    /// An enum type which decodes from Bool?.
    private enum EnhancedBool: Codable {
        case `true`
        case `false`
        case fileNotFound
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                self = .fileNotFound
            } else {
                let value = try container.decode(Bool.self)
                self = value ? .true : .false
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .true: try container.encode(true)
            case .false: try container.encode(false)
            case .fileNotFound: try container.encodeNil()
            }
        }
    }
    
    // MARK: - Encoding Optional Types
    
    func testEncodingSingleOptionalTypes() {
        let nilSymbol = NilEncodingStrategy.defaultNilSymbol
        
        testRoundTrip(of: false as Bool?, expectedEncodedValue: false)
        testRoundTrip(of: true as Bool?, expectedEncodedValue: true)
        testRoundTrip(of: nil as Bool?, expectedEncodedValue: nilSymbol)
        
        testRoundTrip(of: Int.max as Int?, expectedEncodedValue: Int.max)
        testRoundTrip(of: nil as Int?, expectedEncodedValue: nilSymbol)
        
        testRoundTrip(of: Int8.max as Int8?, expectedEncodedValue: Int8.max)
        testRoundTrip(of: nil as Int8?, expectedEncodedValue: nilSymbol)
        
        testRoundTrip(of: Int64.max as Int64?, expectedEncodedValue: Int64.max)
        testRoundTrip(of: nil as Int64?, expectedEncodedValue: nilSymbol)
        
        testRoundTrip(of: UInt.max as UInt?, expectedEncodedValue: UInt.max)
        testRoundTrip(of: nil as UInt?, expectedEncodedValue: nilSymbol)
        
        testRoundTrip(of: UInt8.max as UInt8?, expectedEncodedValue: UInt8.max)
        testRoundTrip(of: nil as UInt8?, expectedEncodedValue: nilSymbol)
        
        testRoundTrip(of: UInt64.max as UInt64?, expectedEncodedValue: UInt64.max)
        testRoundTrip(of: nil as UInt64?, expectedEncodedValue: nilSymbol)
        
        testRoundTrip(of: Float.greatestFiniteMagnitude as Float?,
                      expectedEncodedValue: Float.greatestFiniteMagnitude)
        testRoundTrip(of: nil as Float?, expectedEncodedValue: nilSymbol)
        
        testRoundTrip(of: Float.greatestFiniteMagnitude as Float?,
                      expectedEncodedValue: Float.greatestFiniteMagnitude)
        testRoundTrip(of: nil as Float?, expectedEncodedValue: nilSymbol)
        
        testRoundTrip(of: Double.greatestFiniteMagnitude as Double?,
                      expectedEncodedValue: Double.greatestFiniteMagnitude)
        testRoundTrip(of: nil as Double?, expectedEncodedValue: nilSymbol)
        
        testRoundTrip(of: "Hello" as String?, expectedEncodedValue: "Hello")
        testRoundTrip(of: nil as String?, expectedEncodedValue: nilSymbol)
        
        let url = URL(string: "https://apple.com")!
        testRoundTrip(of: url as URL?, expectedEncodedValue: ["relative": "https://apple.com"])
        testRoundTrip(of: nil as URL?, expectedEncodedValue: nilSymbol)
        
        let data = Data([0xAB, 0xDE, 0xF3, 0x05])
        testRoundTrip(of: data as Data?, expectedEncodedValue: data)
        testRoundTrip(of: nil as Data?, expectedEncodedValue: nilSymbol)
        
        let date = Date()
        testRoundTrip(of: date as Date?, expectedEncodedValue: date)
        testRoundTrip(of: nil as Date?, expectedEncodedValue: nilSymbol)
        
        testRoundTrip(of: Switch.off as Switch?, expectedEncodedValue: false)
        testRoundTrip(of: nil as Switch?, expectedEncodedValue: nilSymbol)
    }
    
    func testEncodingStructuredOptionalTypes() {
        testRoundTrip(of: nil as OptStruct?)
        
        let nonOptStruct = OptStruct(
            bool: true, int: 2, float: 5.0, string: "hello", counter: Counter(7),
            intArr1: [1, nil, 3, nil], intArr2: [nil, 2, nil, 4],
            strArr1: ["a", nil, "c", nil], strArr2: [nil, "b", nil, "d"],
            counterArr1: [Counter(1), nil, Counter(3)], counterArr2: [nil, Counter(2), nil],
            intsByStr: ["a": 1, "b": nil, "c": 3],
            strsByStr: ["a": nil, "b": "2", "c": nil],
            countersByStr: ["a": Counter(1), "b": nil, "c": Counter(3)]
        )
        testRoundTrip(of: nonOptStruct)
        testRoundTrip(of: nonOptStruct as OptStruct?)
        
        let optStruct = OptStruct(
            bool: nil, int: nil, float: nil, string: nil, counter: nil,
            intArr1: [], intArr2: nil,
            strArr1: [], strArr2: nil,
            counterArr1: [], counterArr2: nil,
            intsByStr: [:],
            strsByStr: [:],
            countersByStr: [:]
        )
        testRoundTrip(of: optStruct)
        testRoundTrip(of: optStruct as OptStruct?)
    }
    
    private struct OptStruct: Codable, Equatable {
        let bool: Bool?
        let int: Int?
        let float: Float?
        let string: String?
        let counter: Counter?
        
        let intArr1: [Int?]
        let intArr2: [Int?]?
        
        let strArr1: [String?]
        let strArr2: [String?]?
        
        let counterArr1: [Counter?]
        let counterArr2: [Counter?]?
        
        let intsByStr: [String: Int?]
        let strsByStr: [String: String?]
        let countersByStr: [String: Counter?]
    }
    
    // MARK: - Encoder Features
    
    func testNestedContainerCodingPaths() {
        let encoder = ObjectEncoder()
        do {
            _ = try encoder.encode(NestedContainersTestType(testSuperEncoder: false))
        } catch {
            XCTFail("Caught error during encoding nested container types: \(error)")
        }
    }
    
    func testSuperEncoderCodingPaths() {
        let encoder = ObjectEncoder()
        do {
            _ = try encoder.encode(NestedContainersTestType(testSuperEncoder: true))
        } catch {
            XCTFail("Caught error during encoding nested container types: \(error)")
        }
    }
    
    struct NestedContainersTestType: Encodable {
        let testSuperEncoder: Bool
        
        init(testSuperEncoder: Bool) {
            self.testSuperEncoder = testSuperEncoder
        }
        
        enum TopLevelCodingKeys: Int, CodingKey {
            case a
            case b
            case c
        }
        
        enum IntermediateCodingKeys: Int, CodingKey {
            case one
            case two
        }
        
        func encode(to encoder: Encoder) throws {
            if self.testSuperEncoder {
                var topLevelContainer = encoder.container(keyedBy: TopLevelCodingKeys.self)
                expectEqualPaths(encoder.codingPath, [],
                                 "Top-level Encoder's codingPath changed.")
                expectEqualPaths(topLevelContainer.codingPath, [],
                                 "New first-level keyed container has non-empty codingPath.")
                
                let superEncoder = topLevelContainer.superEncoder(forKey: .a)
                expectEqualPaths(encoder.codingPath, [],
                                 "Top-level Encoder's codingPath changed.")
                expectEqualPaths(topLevelContainer.codingPath, [],
                                 "First-level keyed container's codingPath changed.")
                expectEqualPaths(superEncoder.codingPath, [TopLevelCodingKeys.a],
                                 "New superEncoder had unexpected codingPath.")
                testNestedContainers(in: superEncoder, baseCodingPath: [TopLevelCodingKeys.a])
            } else {
                testNestedContainers(in: encoder, baseCodingPath: [])
            }
        }
        
        private func testNestedContainers(in encoder: Encoder, baseCodingPath: [CodingKey]) {
            expectEqualPaths(encoder.codingPath, baseCodingPath,
                             "New encoder has non-empty codingPath.")
            
            // codingPath should not change upon fetching a non-nested container.
            var firstLevelContainer = encoder.container(keyedBy: TopLevelCodingKeys.self)
            expectEqualPaths(encoder.codingPath, baseCodingPath,
                             "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath,
                             "New first-level keyed container has non-empty codingPath.")
            
            testNestedKeyedContainer(firstLevelContainer: &firstLevelContainer,
                                     in: encoder,
                                     baseCodingPath: baseCodingPath)
            
            testNestedUnkeyedContainer(firstLevelContainer: &firstLevelContainer,
                                       in: encoder,
                                       baseCodingPath: baseCodingPath)
        }
        
        private func testNestedKeyedContainer(
            firstLevelContainer: inout KeyedEncodingContainer<TopLevelCodingKeys>,
            in encoder: Encoder,
            baseCodingPath: [CodingKey]) {
            
            // Nested container for key should have a new key pushed on.
            var secondLevelContainer = firstLevelContainer.nestedContainer(
                keyedBy: IntermediateCodingKeys.self, forKey: .a)
            expectEqualPaths(encoder.codingPath, baseCodingPath,
                             "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath,
                             "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath,
                             baseCodingPath + [TopLevelCodingKeys.a],
                             "New second-level keyed container had unexpected codingPath.")
            
            // Inserting a keyed container should not change existing coding paths.
            let thirdLevelContainerKeyed = secondLevelContainer.nestedContainer(
                keyedBy: IntermediateCodingKeys.self, forKey: .one)
            expectEqualPaths(encoder.codingPath, baseCodingPath,
                             "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath,
                             "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath,
                             baseCodingPath + [TopLevelCodingKeys.a],
                             "Second-level keyed container's codingPath changed.")
            expectEqualPaths(thirdLevelContainerKeyed.codingPath,
                             baseCodingPath + [TopLevelCodingKeys.a, IntermediateCodingKeys.one],
                             "New third-level keyed container had unexpected codingPath.")
            
            // Inserting an unkeyed container should not change existing coding paths.
            let thirdLevelContainerUnkeyed = secondLevelContainer.nestedUnkeyedContainer(
                forKey: .two)
            expectEqualPaths(encoder.codingPath, baseCodingPath,
                             "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath,
                             "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath,
                             baseCodingPath + [TopLevelCodingKeys.a],
                             "Second-level keyed container's codingPath changed.")
            expectEqualPaths(thirdLevelContainerUnkeyed.codingPath,
                             baseCodingPath + [TopLevelCodingKeys.a, IntermediateCodingKeys.two],
                             "New third-level unkeyed container had unexpected codingPath.")
        }
        
        private func testNestedUnkeyedContainer(
            firstLevelContainer: inout KeyedEncodingContainer<TopLevelCodingKeys>,
            in encoder: Encoder,
            baseCodingPath: [CodingKey]) {
            
            // Nested container for key should have a new key pushed on.
            var secondLevelContainer = firstLevelContainer.nestedUnkeyedContainer(forKey: .b)
            expectEqualPaths(encoder.codingPath, baseCodingPath,
                             "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath,
                             "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath,
                             baseCodingPath + [TopLevelCodingKeys.b],
                             "New second-level keyed container had unexpected codingPath.")
            
            // Appending a keyed container should not change existing coding paths.
            let thirdLevelContainerKeyed = secondLevelContainer.nestedContainer(
                keyedBy: IntermediateCodingKeys.self)
            expectEqualPaths(encoder.codingPath, baseCodingPath,
                             "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath,
                             "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath,
                             baseCodingPath + [TopLevelCodingKeys.b],
                             "Second-level unkeyed container's codingPath changed.")
            expectEqualPaths(thirdLevelContainerKeyed.codingPath,
                             baseCodingPath + [TopLevelCodingKeys.b, ObjectKey(index: 0)],
                             "New third-level keyed container had unexpected codingPath.")
            
            // Appending an unkeyed container should not change existing coding paths.
            let thirdLevelContainerUnkeyed = secondLevelContainer.nestedUnkeyedContainer()
            expectEqualPaths(encoder.codingPath, baseCodingPath,
                             "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath,
                             "First-level keyed container's codingPath changed.")
            expectEqualPaths(secondLevelContainer.codingPath,
                             baseCodingPath + [TopLevelCodingKeys.b],
                             "Second-level unkeyed container's codingPath changed.")
            expectEqualPaths(thirdLevelContainerUnkeyed.codingPath,
                             baseCodingPath + [TopLevelCodingKeys.b, ObjectKey(index: 1)],
                             "New third-level unkeyed container had unexpected codingPath.")
        }
    }
    
    // MARK: - Type coercion
    
    func testTypeCoercion() {
        testRoundTripTypeCoercionFailure(of: [false, true], as: [Int].self)
        testRoundTripTypeCoercionFailure(of: [false, true], as: [Int8].self)
        testRoundTripTypeCoercionFailure(of: [false, true], as: [Int16].self)
        testRoundTripTypeCoercionFailure(of: [false, true], as: [Int32].self)
        testRoundTripTypeCoercionFailure(of: [false, true], as: [Int64].self)
        testRoundTripTypeCoercionFailure(of: [false, true], as: [UInt].self)
        testRoundTripTypeCoercionFailure(of: [false, true], as: [UInt8].self)
        testRoundTripTypeCoercionFailure(of: [false, true], as: [UInt16].self)
        testRoundTripTypeCoercionFailure(of: [false, true], as: [UInt32].self)
        testRoundTripTypeCoercionFailure(of: [false, true], as: [UInt64].self)
        testRoundTripTypeCoercionFailure(of: [false, true], as: [Float].self)
        testRoundTripTypeCoercionFailure(of: [false, true], as: [Double].self)
        testRoundTripTypeCoercionFailure(of: [0, 1] as [Int], as: [Bool].self)
        testRoundTripTypeCoercionFailure(of: [0, 1] as [Int8], as: [Bool].self)
        testRoundTripTypeCoercionFailure(of: [0, 1] as [Int16], as: [Bool].self)
        testRoundTripTypeCoercionFailure(of: [0, 1] as [Int32], as: [Bool].self)
        testRoundTripTypeCoercionFailure(of: [0, 1] as [Int64], as: [Bool].self)
        testRoundTripTypeCoercionFailure(of: [0, 1] as [UInt], as: [Bool].self)
        testRoundTripTypeCoercionFailure(of: [0, 1] as [UInt8], as: [Bool].self)
        testRoundTripTypeCoercionFailure(of: [0, 1] as [UInt16], as: [Bool].self)
        testRoundTripTypeCoercionFailure(of: [0, 1] as [UInt32], as: [Bool].self)
        testRoundTripTypeCoercionFailure(of: [0, 1] as [UInt64], as: [Bool].self)
        testRoundTripTypeCoercionFailure(of: [0.0, 1.0] as [Float], as: [Bool].self)
        testRoundTripTypeCoercionFailure(of: [0.0, 1.0] as [Double], as: [Bool].self)
    }
    
    private func testRoundTripTypeCoercionFailure<T, U>(
        of value: T, as type: U.Type,
        file: StaticString = #file, line: UInt = #line
        ) where T: Codable, U: Codable {
        
        do {
            let encodedValue = try ObjectEncoder().encode(value)
            _ = try ObjectDecoder().decode(U.self, from: encodedValue)
            XCTFail("Coercion from \(T.self) to \(U.self) was expected to fail.")
        } catch {}
    }
    
    func testDecodingConcreteTypeParameter() {
        let encoder = ObjectEncoder()
        guard let encoded = try? encoder.encode(Employee.testValue) else {
            XCTFail("Unable to encode Employee.")
            return
        }
        
        let decoder = ObjectDecoder()
        guard let decoded = try? decoder.decode(Employee.self as Person.Type, from: encoded) else {
            XCTFail("Failed to decode Employee as Person from Any.")
            return
        }
        
        XCTAssertTrue(type(of: decoded) == Employee.self,
                      "Expected decoded value to be of type Employee; "
                      + "got \(type(of: decoded)) instead.")
    }
    
    // MARK: - Encoder State
    
    // SR-6078
    func testEncoderStateThrowOnEncode() {
        struct Wrapper<T : Encodable> : Encodable {
            let value: T
            init(_ value: T) { self.value = value }
            
            func encode(to encoder: Encoder) throws {
                // This approximates a subclass calling into its superclass,
                // where the superclass encodes a value that might throw.
                // The key here is that getting the superEncoder creates a referencing encoder.
                var container = encoder.unkeyedContainer()
                let superEncoder = container.superEncoder()
                
                // Pushing a nested container on leaves the referencing encoder
                // with multiple containers.
                var nestedContainer = superEncoder.unkeyedContainer()
                try nestedContainer.encode(value)
            }
        }
        
        struct Throwing : Encodable {
            func encode(to encoder: Encoder) throws {
                enum EncodingError : Error { case foo }
                throw EncodingError.foo
            }
        }
        
        // The structure that would be encoded here looks like
        //
        //   <array>
        //     <array>
        //       <array>
        //         [throwing]
        //       </array>
        //     </array>
        //   </array>
        //
        // The wrapper asks for an unkeyed container ([^]), gets a super encoder,
        // and creates a nested container into that ([[^]]).
        // We then encode an array into that ([[[^]]]), which happens to be a value
        // that causes us to throw an error.
        //
        // The issue at hand reproduces when you have a referencing encoder
        // (superEncoder() creates one) that has a container on the stack
        // (unkeyedContainer() adds one) that encodes a value going through box_() (Array does that)
        // that encodes something which throws (Throwing does that).
        // When reproducing, this will cause a test failure via fatalError().
        _ = try? ObjectEncoder().encode(Wrapper([Throwing()]))
    }
    
    // SR-6048
    func testDecoderStateThrowOnDecode() {
        do {
            let value = [1, 2, 3]
            let encoded = try ObjectEncoder().encode(value)
            let decoded = try ObjectDecoder().decode(EitherDecodable<[String], [Int]>.self,
                                                     from: encoded)
            if case let .u(decodedValue) = decoded {
                XCTAssertEqual(decodedValue, value)
            } else {
                XCTFail("Expected decoded value to be of .u([Int]); got \(decoded) instead.")
            }
        } catch {
            XCTFail("Failed to decode [Int]: \(error)")
        }
    }
    
    private enum EitherDecodable<T: Decodable, U: Decodable>: Decodable {
        case t(T)
        case u(U)
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let t = try? container.decode(T.self) {
                self = .t(t)
            } else if let u = try? container.decode(U.self) {
                self = .u(u)
            } else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Data was neither \(T.self) nor \(U.self)."
                )
            }
        }
    }
    
    func testEncodingNilAsNSNull() {
        let nilStrategy = NilCodingStrategy.null
        let value: Int? = nil
        testRoundTrip(of: value, expectedEncodedValue: NSNull(),
                      nilEncodingStrategy: nilStrategy, nilDecodingStrategy: nilStrategy)
    }
    
    func testEncodingNilAsCustomSymbol() {
        let nilStrategy = NilCodingStrategy.symbol("Custom Nil Value")
        let value: Int? = nil
        testRoundTrip(of: value, expectedEncodedValue: "Custom Nil Value",
                      nilEncodingStrategy: nilStrategy, nilDecodingStrategy: nilStrategy)
    }
    
    // MARK: - Performance
    
    func testPerformanceSeed() {
        let stores = GroceryStore.testValues
        testRoundTrip(of: stores)
    }
    
    func testEncodingPerformance() {
        let stores = GroceryStore.testValues
        
        measure {
            for _ in 0..<10 {
                do {
                    let encoder = ObjectEncoder()
                    _ = try encoder.encode(stores)
                } catch {
                    XCTFail("Failed to encode \(GroceryStore.self): \(error)")
                }
            }
        }
    }
    
    func testDecodingPerformance() {
        let stores = GroceryStore.testValues
        let encodedStores: Any
        do {
            encodedStores = try ObjectEncoder().encode(stores)
        } catch {
            XCTFail("Failed to encode \(GroceryStore.self): \(error)")
            return
        }
        
        measure {
            for _ in 0..<10 {
                do {
                    let decoder = ObjectDecoder()
                    _ = try decoder.decode([GroceryStore].self, from: encodedStores)
                } catch {
                    XCTFail("Failed to decode \(GroceryStore.self): \(error)")
                }
            }
        }
    }
    
    private struct GroceryStore: Codable, Equatable {
        let name: String
        let aisles: [Aisle]
        
        static var testValues: [GroceryStore] {
            return [
                GroceryStore(name: "Home Town Market", aisles: Aisle.testValues),
                GroceryStore(name: "Big City Market", aisles: Aisle.testValues),
                GroceryStore(name: "Home Plus Market", aisles: Aisle.testValues),
                GroceryStore(name: "Small City Market", aisles: Aisle.testValues)
            ]
        }
        
        struct Aisle: Codable, Equatable {
            let name: String
            let shelves: [Shelf]
            
            static var testValues: [Aisle] {
                return [
                    Aisle(name: "Produce", shelves: Shelf.testValues),
                    Aisle(name: "Sale Aisle", shelves: Shelf.testValues)
                ]
            }
        }
        
        struct Shelf: Codable, Equatable {
            let name: String
            let product: Product
            
            static var testValues: [Shelf] {
                return [
                    Shelf(name: "Seasonal Sale", product: Product.testValues[0]),
                    Shelf(name: "Last Season's Clearance", product: Product.testValues[1]),
                    Shelf(name: "Discount Produce", product: Product.testValues[2]),
                    Shelf(name: "Nuts", product: Product.testValues[3])
                ]
            }
        }
        
        struct Product: Codable, Equatable {
            var name: String
            var points: Int
            var description: String?
            
            static var testValues: [Product] {
                return [
                    Product(name: "Banana", points: 200,
                            description: "A banana grown in Eduador."),
                    Product(name: "Orange", points: 100,
                            description: nil),
                    Product(name: "Pumpkin Seeds", points: 400,
                            description: "Seeds harvested from a pumpkin."),
                    Product(name: "Chestnuts", points: 700,
                            description: "Chestnuts that were roasted over an open fire.")
                ]
            }
        }
    }
}

// MARK: - Helper Functions
private func expectEqualPaths(_ lhs: [CodingKey], _ rhs: [CodingKey], _ prefix: String,
                              file: StaticString = #file,
                              line: UInt = #line) {
    if lhs.count != rhs.count {
        XCTFail("\(prefix) [CodingKey].count mismatch: \(lhs.count) != \(rhs.count)",
            file: file, line: line)
        return
    }
    
    let intFailDesc = "\(prefix) CodingKey.intValue mismatch"
    let strFailDesc = "\(prefix) CodingKey.stringValue mismatch"
    
    for (key1, key2) in zip(lhs, rhs) {
        switch (key1.intValue, key2.intValue) {
        case (.none, .none):
            break
        case (.some(let i1), .none):
            XCTFail("\(intFailDesc): \(type(of: key1))(\(i1)) != nil",
                file: file, line: line)
            return
        case (.none, .some(let i2)):
            XCTFail("\(intFailDesc): nil != \(type(of: key2))(\(i2))",
                file: file, line: line)
            return
        case (.some(let i1), .some(let i2)):
            guard i1 == i2 else {
                XCTFail("\(intFailDesc): \(type(of: key1))(\(i1)) != \(type(of: key2))(\(i2))",
                    file: file, line: line)
                return
            }
        }
        
        XCTAssertEqual(key1.stringValue, key2.stringValue,
                       "\(strFailDesc): \(type(of: key1))('\(key1.stringValue)') "
                        + "!= \(type(of: key2))('\(key2.stringValue)')",
            file: file, line: line)
    }
}
