import Foundation
import XcodeGenKit
import ProjectSpec
import JSONUtilities
import PathKit
import Yams
import xcproj

public protocol AppProjectGeneratorDelegate: class {
    func findChildren(_ app: AppSpec) throws -> [FrameworkSpec]
    func findDependencies(_ app: AppSpec) throws -> [Dependency]
    func findBundles(_ app: AppSpec) throws -> [ResourceBundle]
}

public class AppProjectGenerator {
    public typealias Delegate = AppProjectGeneratorDelegate
    
    public let spec: AppSpec
    public let projectPath: Path
    
    weak var delegate: Delegate?
    
    var filesystem: FileSystem = DefaultFileSystem()
    
    public init(
        spec: AppSpec,
        projectPath: Path,
        delegate: Delegate
    ) {
        self.spec = spec
        self.projectPath = projectPath
        self.delegate = delegate
    }
    
    var directory: Path {
        return self.projectPath.parent()
    }
    
    func generateMainTargetFiles() throws {
        let root = self.directory + self.spec.targetName
        let sources = root + "Sources"
        let resources = root + "Resources"
        let config = root + "Config"
        
        let generator = FileGenerator(filesystem: self.filesystem)
        
        let bundles = try findBundles().map { $0.name }
        try generator.generateDirectories([
            root,
            sources,
            resources,
            config
        ])
        
        try generator.generateFiles([
            root + "Info.plist": Plist.app(),
            
            sources + "AppDelegate.swift": SourceFile.appdelegate()
        ])
        
        let childModules = try self.delegate?.findChildren(self.spec).map { $0.targetName } ?? []
        
        try generator.generateFiles([
            sources + "Dependencies.swift": SourceFile.dependencies(
                module: self.spec.name,
                features: childModules,
                bundles: bundles,
                resourceBundleId: nil
            ),
        ], overwrite: true)
    }
    
    func generateUITestFiles() throws {
        let root = self.directory + self.spec.uiTestTargetName
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
            root + "Info.plist": Plist.appUITests()
        ])
        
    }
    
    func generateUnitTestFiles() throws {
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
            root + "Info.plist": Plist.appUnitTests()
        ])
        
    }
    
    func scaffold() throws {
        try self.generateMainTargetFiles()
        try self.generateUnitTestFiles()
        try self.generateUITestFiles()
    }
    
    public func generate() throws {
        let project = try generateProject()
        
        try project.write(path: self.projectPath)
    }
    
    func generateAppTarget() throws -> Target {

        let dependencies = try self.findDependencies()
        
        return Target(
            name: self.spec.targetName,
            type: .application,
            platform: .iOS,
            settings: .init(
                buildSettings: ["INFOPLIST_FILE": "\(self.spec.targetName)/Info.plist"]
            ),
            sources: [TargetSource(path: self.spec.targetName)],
            dependencies: dependencies,
            prebuildScripts: [],
            postbuildScripts: [],
            scheme: TargetScheme(
                testTargets: [
                    self.spec.unitTestTargetName,
                    self.spec.uiTestTargetName
                ],
                gatherCoverageData: true,
                commandLineArguments: [:]
            ),
            legacy: nil
        )
        
    }
    
    
    func generateUnitTestTarget() throws -> Target {
        
        let dependencies = try self.findDependencies()
        
        return Target(
            name: self.spec.unitTestTargetName,
            type: .unitTestBundle,
            platform: .iOS,
            settings: .init(
                buildSettings: ["INFOPLIST_FILE": "\(self.spec.unitTestTargetName)/Info.plist"]
            ),
            sources: [
                TargetSource(path: self.spec.unitTestTargetName)
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
        
    }
    
    func generateUITestTarget() throws -> Target {
        
        let dependencies = try self.findDependencies()
        
        return Target(
            name: self.spec.uiTestTargetName,
            type: .uiTestBundle,
            platform: .iOS,
            settings: .init(
                buildSettings: ["INFOPLIST_FILE": "\(self.spec.uiTestTargetName)/Info.plist"]
            ),
            sources: [
                TargetSource(path: self.spec.uiTestTargetName)
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
        
    }
    
    func generateProject() throws -> XcodeProj {
        
        
        let spec = ProjectSpec(
            basePath: self.directory,
            name: self.spec.name,
            configs: [
                Config(name: "Debug", type: .debug),
                Config(name: "Distribution", type: .release),
                Config(name: "Release", type: .release),
                ],
            targets: [
                try generateAppTarget(),
                try generateUnitTestTarget(),
                try generateUITestTarget()
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
    
    func findDependencies() throws -> [Dependency] {
        return try self.delegate?.findDependencies(self.spec) ?? []
    }
    
    
    func findBundles() throws -> [ResourceBundle] {
        return try self.delegate?.findBundles(self.spec) ?? []
    }
    
}


