import Foundation
import XcodeGenKit
import ProjectSpec
import JSONUtilities
import PathKit
import Yams
import xcproj


public class FrameworkProjectGenerator {
    public typealias DependencyResolver = (FeatureSpec) throws -> [Dependency]
    
    public let spec: FeatureSpec
    public let projectPath: Path
    var dependencyResolver: DependencyResolver
    
    var directory: Path {
        return projectPath.parent()
    }
    
    var filesystem: FileSystem = DefaultFileSystem()
    
    public init(
        spec: FeatureSpec,
        projectPath: Path,
        dependencyResolver: @escaping DependencyResolver
    ) {
        self.spec = spec
        self.projectPath = projectPath
        self.dependencyResolver = dependencyResolver
    }
    
    func generateMainTargetFiles() throws {
        let root = self.directory + self.spec.targetName
        let sources = root + "Sources"
        let resources = root + "Resources"
        let config = root + "Config"
        
        let generator = FileGenerator(filesystem: self.filesystem)
        
        try generator.generateDirectories([
            root,
            sources,
            resources,
            config
        ])
        
        try generator.generateFiles([
            root + "Info.plist": Plist.frameworkTarget(),
            sources + "Dependencies.swift": SourceFile.dependencies(feature: self.spec.name)
        ])
        
    }
    
    func generateTestTargetFiles() throws {
        let root = self.directory + self.spec.unitTestTargetName
        let sources = root + "Sources"
        let resources = root + "Resources"
        let config = root + "Config"
        
        let generator = FileGenerator(filesystem: self.filesystem)
        
        try generator.generateDirectories([
            root,
            sources,
            resources,
            config
            ])
        
        try generator.generateFiles([
            root + "Info.plist": Plist.frameworkTargetTests()
            ])
        
    }
    
    func scaffold() throws {
        try self.generateMainTargetFiles()
        try self.generateTestTargetFiles()
    }
    
    
    func generateDependencies() throws -> [Dependency] {
        return try dependencyResolver(self.spec)
    }
    
    func generate() throws {
        let project = try self.generateProject()
        
        try project.write(path: self.projectPath)
    }
    
    func generateProject() throws -> XcodeProj {
        
        let dependencies = try self.generateDependencies()
        
        let targetName = self.spec.targetName
        let testTargetName = self.spec.unitTestTargetName
        
        // MARK: - Framework Target
        let frameworkTarget = Target(
            name: targetName,
            type: .framework,
            platform: .iOS,
            sources: [
                TargetSource(path: targetName)
            ],
            dependencies: dependencies,
            prebuildScripts: [],
            postbuildScripts: [],
            scheme: TargetScheme(
                testTargets: [testTargetName],
                gatherCoverageData: true,
                commandLineArguments: [:]
            ),
            legacy: nil
        )
        
        
        // MARK: - Test Target
        let testTarget = Target(
            name: testTargetName,
            type: .unitTestBundle,
            platform: .iOS,
            sources: [
                TargetSource(path: testTargetName)
            ],
            dependencies: dependencies,
            prebuildScripts: [],
            postbuildScripts: [],
            scheme: TargetScheme(
                testTargets: [],
                gatherCoverageData: true,
                commandLineArguments: [:]
            ),
            legacy: nil
        )
        
        let spec = ProjectSpec(
            basePath: self.directory,
            name: self.spec.name,
            configs: [
                Config(name: "Debug", type: .debug),
                Config(name: "Distribution", type: .release),
                Config(name: "Release", type: .release),
                ],
            targets: [
                frameworkTarget,
                testTarget,
                ],
            settings: Settings(
                buildSettings: [:],
                configSettings: [:],
                groups: []
            ),
            settingGroups: [:],
            schemes: [],
            options: .init(
                carthageBuildPath: "../Carthage/Build",
                bundleIdPrefix: "at.imobility"
            ),
            fileGroups: [],
            configFiles: [:],
            attributes: [:]
        )
        
        let generator = ProjectGenerator(
            spec: spec
        )
        
        return try generator.generateProject()
    }
}

