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
            projectPath: self.directory + "\(feature.name)/\(feature.name).xcodeproj",
            dependencyResolver: self.generateDependencies(feature:)
        )
        
        try generator.scaffold()
        
    }
    
    public func scaffold(app: AppSpec) throws {
        let generator = AppProjectGenerator(
            spec: app,
            projectPath: self.directory + "\(app.name)/\(app.name).xcodeproj",
            dependencyResolver: self.generateDependencies(app:)
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
            projectPath: self.directory + "\(feature.name)/\(feature.name).xcodeproj",
            dependencyResolver: self.generateDependencies(feature:)
        )
        
        try generator.generate()
        
    }
    
    public func generate(app: AppSpec) throws {
        
        let generator = AppProjectGenerator(
            spec: app,
            projectPath: self.directory + "\(app.name)/\(app.name).xcodeproj",
            dependencyResolver: self.generateDependencies(app:)
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

extension WorkspaceGenerator {
    
    func feature(for name: String) -> FeatureSpec? {
        return self.spec.features.first { $0.name == name }
    }
    
    func carthage(for name: String) -> FeatureSpec? {
        return self.spec.features.first { $0.name == name }
    }
    
    func flattenedCarthageDependencies(feature: FeatureSpec) -> Set<String>  {
        var result = Set<String>(feature.carthageDependencies ?? [])
        
        let deps = feature.dependencies ?? []
        let subFeatures = deps.flatMap { self.feature(for: $0) }
        
        for f in subFeatures {
            result.formUnion(self.flattenedCarthageDependencies(feature: f))
        }
        
        return result
    }
    
    func generateDependencies(app: AppSpec) -> [Dependency] {
        
        let deps = app.dependencies ?? []
        
        let subFeatures = deps.flatMap { self.feature(for: $0) }
        
        var carthageDepNames = Set<String>(app.carthageDependencies ?? [])
        
        for f in subFeatures {
            carthageDepNames.formUnion(self.flattenedCarthageDependencies(feature: f))
        }
        
        
        let carthageDeps = carthageDepNames.map {
            return Dependency(
                type: .carthage,
                reference: $0,
                embed: true,
                link: true,
                implicit: false
            )
        }
        
        var dependencies = subFeatures.map {
            return Dependency(
                type: .framework,
                reference: "\($0.name).framework",
                embed: true,
                link: true,
                implicit: true
            )
        }
        
        dependencies.append(contentsOf: carthageDeps)
        
        return dependencies
    }
    
    func generateDependencies(feature: FeatureSpec) -> [Dependency] {
        
        let deps = feature.dependencies ?? []
        
        let subFeatures = deps.flatMap { self.feature(for: $0) }
        
        var carthageDepNames = Set<String>(feature.carthageDependencies ?? [])
        
        for f in subFeatures {
            carthageDepNames.formUnion(self.flattenedCarthageDependencies(feature: f))
        }
        
        
        let carthage: [Dependency] = carthageDepNames
            .map { Dependency.init(
                type: .carthage,
                reference: $0,
                embed: false,
                link: true,
                implicit: false)
        }
        
        var dependencies: [Dependency] = feature.dependencies?
            .map { Dependency.init(
                type: .framework,
                reference: "\($0).framework",
                embed: false,
                link: true,
                implicit: true)
            } ?? []
        
        dependencies.append(contentsOf: carthage)
        
        return dependencies
    }
    
}
