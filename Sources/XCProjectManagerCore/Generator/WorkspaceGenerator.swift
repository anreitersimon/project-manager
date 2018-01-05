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
    public let makeFilePath: Path
    
    var filesystem: FileSystem = DefaultFileSystem()
    
    public init(
        spec: WorkspaceSpec,
        workspacePath: Path,
        makeFilePath: Path
    ) {
        self.spec = spec
        self.workspacePath = workspacePath
        self.makeFilePath = makeFilePath
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
        
        let makeFile = try Makefile.generate(try self.generateTargets())
        
        let fileGenerator = FileGenerator(filesystem: self.filesystem)
        
        try fileGenerator.generateFiles([self.makeFilePath : makeFile], overwrite: true)
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
    
    public func generateTargets() throws -> [Target] {
        return [
            try self.spec.apps.flatMap { try self.generator(for: $0).generateTargets() },
            try self.spec.features.flatMap { try self.generator(for: $0).generateTargets() },
        ].flatMap { $0 }
    }
    
    
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

    
}

extension WorkspaceGenerator: FrameworkProjectGenerator.Delegate {
    
    public func dependencies(of app: AppSpec) throws -> DependencyDeclaration {
        
        return recursiveDependencies(app)
            .reduce(DependencyDeclaration()) { (sum, part) in
                return sum + declare(part) + dependencies(of: part)
        }
    }
    
    func declare(_ framework: FrameworkSpec) -> DependencyDeclaration {
        return DependencyDeclaration(
            carthage: Set(framework.carthage ?? []),
            frameworkList: [framework],
            bundleList: [ resourceBundle(framework) ]
        )
    }

    
    public func dependencies(of framework: FrameworkSpec) -> DependencyDeclaration {
        let deps = recursiveDependencies(framework)
        
        return deps.reduce(DependencyDeclaration()) { sum, part in
            return sum + declare(part) + dependencies(of: part)
        }
    }
    
    func resourceBundle(_ framework: FrameworkSpec) -> ResourceBundle {
        return ResourceBundle(
            bundleId: "at.imobility.\(framework.resourceTargetName.lowercased())",
            name: framework.resourceTargetName,
            path: Path(framework.resourceTargetName)
        )
    }
    
}

extension WorkspaceGenerator: AppProjectGenerator.Delegate {

    
    private func nameToSpecs(_ value: [FrameworkSpec]) -> [String: FrameworkSpec] {
        let nameAndSpec = value.map { ($0.name, $0) }
        
        return Dictionary(nameAndSpec) { old,_ in old  }
    }
    
    
    private func nameToBundles(_ value: [ResourceBundle]) -> [String: ResourceBundle] {
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
    
}
