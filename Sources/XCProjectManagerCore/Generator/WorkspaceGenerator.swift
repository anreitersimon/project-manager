import Foundation
import XcodeGenKit
import ProjectSpec
import JSONUtilities
import PathKit
import Yams
import xcproj

public class WorkspaceGenerator {
    public let spec: WorkspaceSpec
    public let workspacePath: Path
    
    var filesystem: FileSystem = DefaultFileSystem()
    
    public init(
        spec: WorkspaceSpec,
        workspacePath: Path
    ) {
        self.spec = spec
        self.workspacePath = workspacePath
    }
    
    var directory: Path {
        return self.workspacePath.parent()
    }
}

// MARK: - Scaffold
extension WorkspaceGenerator {
 
    public func scaffold() throws {
        try self.spec.apps.forEach(self.scaffold(app:))
        try self.spec.features.forEach(self.scaffold(feature:))
    }

    public func scaffold(feature: FeatureSpec) throws {
        let generator = FrameworkProjectGenerator(
            spec: feature,
            projectPath: self.directory + "\(feature.name)/\(feature.name).xcodeproj"
        )
        
        try generator.scaffold()
        
    }
    
    public func scaffold(app: AppSpec) throws {
        let generator = AppProjectGenerator(
            spec: app,
            projectPath: self.directory + "\(app.name)/\(app.name).xcodeproj",
            dependencyResolver: self.generateAppDependencies
        )
        
        try generator.scaffold()
        
    }
}


// MARK: - Generate
extension WorkspaceGenerator {
    
    public func generate() throws {
        let workspace = try generateWorkSpace()
        
        try workspace.write(path: self.workspacePath)
        
        try self.spec.apps.forEach(self.generate(app:))
        try self.spec.features.forEach(self.generate(feature:))
    }
    
    public func generate(feature: FeatureSpec) throws {
        let generator = FrameworkProjectGenerator(
            spec: feature,
            projectPath: self.directory + "\(feature.name)/\(feature.name).xcodeproj"
        )
        
        try generator.generate()
        
    }
    
    public func generate(app: AppSpec) throws {
        
        let generator = AppProjectGenerator(
            spec: app,
            projectPath: self.directory + "\(app.name)/\(app.name).xcodeproj",
            dependencyResolver: self.generateAppDependencies
        )
        
        try generator.generate()
        
    }
    
    func generateWorkSpace() throws -> XCWorkspace {
        
        var refs: [XCWorkspace.Data.FileRef] = self.spec.files?
            .map { .other(location: "group:\($0)") } ?? []
        
        for app in self.spec.apps {
            refs.append(.other(location: "group:\(app.name)/\(app.name).xcodeproj"))
        }
        
        for feature in self.spec.features {
            refs.append(.other(location: "group:\(feature.name)/\(feature.name).xcodeproj"))
        }
        
        return XCWorkspace(
            data: .init(
                references: refs
            )
        )
    }
}
