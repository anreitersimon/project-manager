import ProjectSpec
import JSONUtilities
import PathKit

public struct ResourceBundle: JSONObjectConvertible, Hashable {

    
    public let bundleId: String
    public let name: String
    
    public let path: Path
    
    public init(
        bundleId: String,
        name: String,
        path: Path
    ) {
        self.bundleId = bundleId
        self.name = name
        self.path = path
    }
    
    public init(jsonDictionary: JSONDictionary) throws {
        bundleId = try jsonDictionary.json(atKeyPath: "bundleId")
        name = try jsonDictionary.json(atKeyPath: "name")
        
        let pathString: String = try jsonDictionary.json(atKeyPath: "path")
        
        self.path = Path(pathString)
    }
    
    public var hashValue: Int {
        return bundleId.hashValue
    }
    
    public static func ==(lhs: ResourceBundle, rhs: ResourceBundle) -> Bool {
        guard lhs.bundleId == rhs.bundleId else { return false }
        guard lhs.name == rhs.name else { return false }
        guard lhs.path == rhs.path else { return false }
        
        return true
    }
}

public protocol SpecProtocol {
    var name: String { get }
    
    var carthage: [String]? { get }    
    var dependencies: [String]? { get }
    
}

public struct FrameworkSpec: SpecProtocol, NamedJSONDictionaryConvertible {
    
    public let name: String
    
    public let carthage: [String]?
    public let dependencies: [String]?
    
    
    public init(name: String, jsonDictionary: JSONDictionary) throws {
        self.name = name
        
        carthage = jsonDictionary.json(atKeyPath: "carthage")
        dependencies = jsonDictionary.json(atKeyPath: "dependencies")
    }
    
    public init(
        name: String,
        carthage: [String]  = [],
        dependencies: [String] = []
    ) {
        self.name = name
        self.carthage = carthage
        self.dependencies = dependencies
        
    }
}

extension FrameworkSpec {

    public var targetName: String {
        return self.name
    }
    
    public var unitTestTargetName: String {
        return "\(self.name)Tests"
    }
    
    public var resourceTargetName: String {
        return "\(self.name)Resources"
    }
    
    public var resourceTargetBundleId: String {
        return "at.imobility.\(self.name.lowercased()).resources"
    }
    
}

