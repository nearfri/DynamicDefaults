
import XCTest
@testable import Defaults

// ref.: https://github.com/apple/swift/blob/master/test/stdlib/TestPlistEncoder.swift

class ObjectCoderTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
        file: StaticString = #file,
        line: UInt = #line) where T: Codable, T: Equatable, U: Equatable {
        
        var encodedValue: Any! = nil
        do {
            let encoder = ObjectEncoder()
            encodedValue = try encoder.encode(value)
        } catch {
            XCTFail("Failed to encode \(T.self): \(error)", file: file, line: line)
        }
        
        if let encodedValue = encodedValue as? U {
            XCTAssertEqual(encodedValue, expectedEncodedValue,
                           "Encoded value is not identical to expected value.",
                           file: file, line: line)
        } else {
            XCTFail("(\"\(String(describing: encodedValue))\") is not equal to "
                + "(\"\(expectedEncodedValue)\") "
                + "- Encoded value is not identical to expected value.", file: file, line: line)
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
    
    func testEncodingTopLevelEmptyClass() {
        let empty = EmptyClass()
        testRoundTrip(of: empty, expectedEncodedValue: emptyDictionary)
    }
    
    private class EmptyClass: Codable, Equatable {
        static func == (_ lhs: EmptyClass, _ rhs: EmptyClass) -> Bool {
            return true
        }
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
    
    func testEncodingTopLevelStructuredStruct() {
        let address = Address.testValue
        testRoundTrip(of: address)
    }
    
    private func testRoundTrip<T>(
        of value: T,
        file: StaticString = #file,
        line: UInt = #line) where T: Codable, T: Equatable {
        
        var encodedValue: Any! = nil
        do {
            let encoder = ObjectEncoder()
            encodedValue = try encoder.encode(value)
        } catch {
            XCTFail("Failed to encode \(T.self): \(error)", file: file, line: line)
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
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "The Numbers are wrong!"))
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
            expectEqualPaths(encoder.codingPath, baseCodingPath + [],
                             "Top-level Encoder's codingPath changed.")
            expectEqualPaths(firstLevelContainer.codingPath, baseCodingPath + [],
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
    
    func testEncodingTopLevelData() {
        let data = Data(bytes: [0xAB, 0xDE, 0xF3, 0x05])
        testRoundTrip(of: data, expectedEncodedValue: data)
    }
    
    func testEncodingTopLevelDate() {
        let date = Date()
        testRoundTrip(of: date, expectedEncodedValue: date)
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
        of value: T, as type: U.Type) where T: Codable, U: Codable {
        
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



