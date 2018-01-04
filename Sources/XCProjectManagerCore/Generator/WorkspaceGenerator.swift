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
    
    func generator(for framework: FrameworkSpec) -> FrameworkProjectGenerator {
        return FrameworkProjectGenerator(
            spec: framework,
            projectPath: self.directory + "\(framework.name)/\(framework.name).xcodeproj",
            delegate: self
        )
    }
    
    func generator(for app: AppSpec) -> AppProjectGenerator {
        return AppProjectGenerator(
            spec: app,
            projectPath: self.directory + "\(app.name)/\(app.name).xcodeproj",
            delegate: self
        )
    }
 
    public func scaffold() throws {
        try self.spec.apps.forEach(self.scaffold(app:))
        try self.spec.features.forEach(self.scaffold(feature:))
    }

    public func scaffold(feature: FrameworkSpec) throws {
        
        try self.generator(for: feature).scaffold()
        
    }
    
    public func scaffold(app: AppSpec) throws {
        try self.generator(for: app).scaffold()
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
    
    public func generate(feature: FrameworkSpec) throws {
        try self.generator(for: feature).generate()
    }
    
    public func generate(app: AppSpec) throws {
        try self.generator(for: app).generate()
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
    
    func feature(for name: String) -> FrameworkSpec? {
        return self.spec.features.first { $0.name == name }
    }
    
    func carthage(for name: String) -> FrameworkSpec? {
        return self.spec.features.first { $0.name == name }
    }
    
    func flattenedCarthageDependencies(feature: FrameworkSpec) -> Set<String>  {
        var result = Set<String>(feature.carthage ?? [])
        
        let deps = feature.dependencies ?? []
        let subFeatures = deps.flatMap { self.feature(for: $0) }
        
        for f in subFeatures {
            result.formUnion(self.flattenedCarthageDependencies(feature: f))
        }
        
        return result
    }
    
    func flattenedBundles(feature: FrameworkSpec) -> Set<ResourceBundle>  {

        var result = Set<ResourceBundle>([self.resourceBundle(feature)])
        
        let deps = feature.dependencies ?? []
        let subFeatures = deps.flatMap { self.feature(for: $0) }
        
        for f in subFeatures {
            result.formUnion(self.flattenedBundles(feature: f))
        }
        
        return result
    }
    
}

extension WorkspaceGenerator: FrameworkProjectGenerator.Delegate {
    
    
    public func findDependencies(_ framework: FrameworkSpec) throws -> [Dependency] {
        
        let deps = framework.dependencies ?? []
        
        let subFeatures = deps.flatMap { self.feature(for: $0) }
        
        var carthageDepNames = Set<String>(framework.carthage ?? [])
        
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
        
        var dependencies: [Dependency] = framework.dependencies?
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
    
    func resourceBundle(_ framework: FrameworkSpec) -> ResourceBundle {
        return ResourceBundle(
            bundleId: "at.imobility.\(framework.resourceTargetName.lowercased())",
            name: framework.resourceTargetName,
            path: Path(framework.resourceTargetName)
        )
    }
    
    public func findBundles(_ framework: FrameworkSpec) throws -> [ResourceBundle] {
        let deps = framework.dependencies ?? []
        
        let subFeatures = deps.flatMap { self.feature(for: $0) }
        
        var resourceBundles = Set([self.resourceBundle(framework)])
        
        for f in subFeatures {
            resourceBundles.formUnion(self.flattenedBundles(feature: f))
        }
        
        return Array(resourceBundles)
    }

}

extension WorkspaceGenerator: AppProjectGenerator.Delegate {
    public func findChildren(_ app: AppSpec) throws -> [FrameworkSpec] {
        return recursiveDependencies(app)
    }
    
    public func findChildren(_ framework: FrameworkSpec) throws -> [FrameworkSpec] {
        return recursiveDependencies(framework)
    }
    
    private func nameToSpecs(_ value: [FrameworkSpec]) -> [String: FrameworkSpec] {
        let nameAndSpec = value.map { ($0.name, $0) }
        
        return Dictionary(nameAndSpec) { old,_ in old  }
    }
    
    
    public func recursiveDependencies(_ app: AppSpec) -> [FrameworkSpec] {
        
        guard let dependencies = app.dependencies else { return [] }
        
        let subspecs = dependencies
            .flatMap { self.feature(for: $0) }
        
        var nameToSpec = nameToSpecs(subspecs)
        
        for spec in subspecs {
            let childDeps = recursiveDependencies(spec).map { ($0.name, $0) }
            
            nameToSpec.merge(childDeps) { (old,_) in old }
        }
        
        return Array(nameToSpec.values)
    }
    
    public func recursiveDependencies(_ framework: FrameworkSpec) -> [FrameworkSpec] {
        
        guard let dependencies = framework.dependencies else { return [] }
        
        let subspecs = dependencies
            .flatMap { self.feature(for: $0) }
        
        var nameToSpec = nameToSpecs(subspecs)
        
        for spec in subspecs {
            let childDeps = recursiveDependencies(spec).map { ($0.name, $0) }
            
            nameToSpec.merge(childDeps) { (old,_) in old }
        }
        
        return Array(nameToSpec.values)
    }
    
    
    public func findDependencies(_ app: AppSpec) throws -> [Dependency] {
        
        let deps = app.dependencies ?? []
        
        let subFeatures = deps.flatMap { self.feature(for: $0) }
        
        let childCarthageDeps = recursiveDependencies(app)
            .flatMap { $0.carthage ?? [] }
        
        let carthageDepNames = Set<String>(app.carthage ?? [])
            .union(childCarthageDeps)
        
        
        let carthageDeps = carthageDepNames.map {
            return Dependency(
                type: .carthage,
                reference: $0,
                embed: true,
                link: true,
                implicit: false
            )
        }
        
        
        let resourceBundles = Set<ResourceBundle>(try findBundles(app))
        
        let resourceBundleDeps = resourceBundles.map {
            return Dependency(
                type: .resourceBundle,
                reference: "\($0.name).bundle",
                embed: true,
                link: false,
                implicit: true
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
        dependencies.append(contentsOf: resourceBundleDeps)
        
        return dependencies
    }
    
    public func findBundles(_ app: AppSpec) throws -> [ResourceBundle] {
        let deps = app.dependencies ?? []
        
        let subFeatures = deps.flatMap { self.feature(for: $0) }
        
        var resourceBundles = Set(app.resourceBundles ?? [])
        
        for f in subFeatures {
            resourceBundles.formUnion(self.flattenedBundles(feature: f))
        }
        
        return Array(resourceBundles)
    }
    
    
}
