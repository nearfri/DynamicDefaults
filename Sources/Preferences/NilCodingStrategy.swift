import Foundation

public enum NilCodingStrategy {
    case null           // NSNull
    case symbol(String) // symbol like "$null"
    
    public var nilValue: Any {
        switch self {
        case .null:
            return NSNull()
        case let .symbol(nilSymbol):
            return nilSymbol
        }
    }
    
    public func isNilValue(_ value: Any) -> Bool {
        switch (self, value) {
        case (.null, _ as NSNull):
            return true
        case let (.symbol(nilSymbol), value as String):
            return nilSymbol == value
        default:
            return false
        }
    }
}

public typealias NilEncodingStrategy = NilCodingStrategy
public typealias NilDecodingStrategy = NilCodingStrategy

extension NilCodingStrategy {
    public static let `default`: NilCodingStrategy = .symbol(NilCodingStrategy.defaultNilSymbol)
    public static let defaultNilSymbol: String = "$null"
}
