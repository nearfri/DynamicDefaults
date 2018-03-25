
import Foundation

internal struct PlistObjectKey: CodingKey {
    public let stringValue: String
    public let intValue: Int?
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    public init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
    
    public init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }
    
    public static let superKey = PlistObjectKey(stringValue: "super")!
}



