import JSONUtilities
import XcodeGenKit
import ProjectSpec

public struct AppSpec: NamedJSONDictionaryConvertible {
    public let name: String
    
    public let carthageDependencies: [String]?
    public let dependencies: [String]?
    
    public init(name: String, jsonDictionary: JSONDictionary) throws {
        self.name = name
        
        carthageDependencies = jsonDictionary.json(atKeyPath: "carthageDependencies")
        dependencies = jsonDictionary.json(atKeyPath: "dependencies")
    }
}

extension AppSpec {
    
    public var targetName: String {
        return self.name
    }
    
    public var unitTestTargetName: String {
        return "\(self.name)Tests"
    }
    
    public var uiTestTargetName: String {
        return "\(self.name)UI-Tests"
    }
}

