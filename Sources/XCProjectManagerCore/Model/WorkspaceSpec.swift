import JSONUtilities

public struct WorkspaceSpec: JSONObjectConvertible {
    
    public let name: String
    public let files: [String]?
    public let apps: [AppSpec]
    public let features: [FeatureSpec]
    
    public init(jsonDictionary: JSONDictionary) throws {
        name = try jsonDictionary.json(atKeyPath: "name")
        files = jsonDictionary.json(atKeyPath: "files")
        
        apps = try jsonDictionary.json(atKeyPath: "apps")
        features = try jsonDictionary.json(atKeyPath: "features")
    }
    
}
