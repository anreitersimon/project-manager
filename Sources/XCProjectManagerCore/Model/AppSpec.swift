import JSONUtilities
import XcodeGenKit
import ProjectSpec

public struct AppSpec: SpecProtocol, NamedJSONDictionaryConvertible {

    public let name: String
    
    public let bundleIdentifier: String?
    
    public let carthage: [String]?
    public let dependencies: [String]?
    public let resourceBundles: [ResourceBundle]?
    public let staticLibraryCompatible: Bool?
    
    
    public init(name: String, jsonDictionary: JSONDictionary) throws {
        self.name = name
        
        bundleIdentifier = jsonDictionary.json(atKeyPath: "bundleIdentifier")
        carthage = jsonDictionary.json(atKeyPath: "carthage")
        dependencies = jsonDictionary.json(atKeyPath: "dependencies")
        resourceBundles = jsonDictionary.json(atKeyPath: "resourceBundles")
        staticLibraryCompatible = jsonDictionary.json(atKeyPath: "staticLibraryCompatible")
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

