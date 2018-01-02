import ProjectSpec
import JSONUtilities

public struct FeatureSpec: NamedJSONDictionaryConvertible {
    
    public let name: String
    
    public let carthageDependencies: [String]?
    public let dependencies: [String]?
    
    public init(name: String, jsonDictionary: JSONDictionary) throws {
        self.name = name
        
        carthageDependencies = jsonDictionary.json(atKeyPath: "carthageDependencies")
        dependencies = jsonDictionary.json(atKeyPath: "dependencies")
    }
    
    public init(
        name: String,
        carthageDependencies: [String]  = [],
        dependencies: [String] = []
    ) {
        self.name = name
        self.carthageDependencies = carthageDependencies
        self.dependencies = dependencies
    }
}

extension FeatureSpec {
    
    public var targetName: String {
        return self.name
    }
    
    public var unitTestTargetName: String {
        return "\(self.name)Tests"
    }
    
}

