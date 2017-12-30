import Foundation
import Rainbow

public struct Logger {
    
    // MARK: - Properties
    public let isQuiet: Bool
    public let isColored: Bool
    
    // MARK: - Initializers
    public init(isQuiet: Bool = false, isColored: Bool = true) {
        self.isQuiet = isQuiet
        self.isColored = isColored
    }
    
    // MARK: - Logging
    public func error(_ message: String) {
        print(isColored ? message.red : message)
    }
    
    public func info(_ message: String) {
        if isQuiet {
            return
        }
        
        print(message)
    }
    
    public func success(_ message: String) {
        if isQuiet {
            return
        }
        
        print(isColored ? message.green : message)
    }
}
