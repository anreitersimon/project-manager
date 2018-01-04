import Foundation
import XcodeGenKit
import ProjectSpec
import JSONUtilities
import PathKit
import Yams
import xcproj

public protocol FrameworkProjectGeneratorDelegate: class {
    func findChildren(_ framework: FrameworkSpec) throws -> [FrameworkSpec]
    func findDependencies(_ framework: FrameworkSpec) throws -> [Dependency]
    func findBundles(_ framework: FrameworkSpec) throws -> [ResourceBundle]
}


public class FrameworkProjectGenerator {
    
    public typealias Delegate = FrameworkProjectGeneratorDelegate
    
    public let spec: FrameworkSpec
    public let projectPath: Path
    weak var delegate: Delegate?
    
    var directory: Path {
        return projectPath.parent()
    }
    
    var filesystem: FileSystem = DefaultFileSystem()
    
    public init(
        spec: FrameworkSpec,
        projectPath: Path,
        delegate: Delegate
    ) {
        self.spec = spec
        self.projectPath = projectPath
        self.delegate = delegate
    }
    
    func generateMainTargetFiles() throws {
        let root = self.directory + self.spec.targetName
        let sources = root + "Sources"
        let config = root + "Config"
        
        let bundles = try self.findBundles().map { $0.name }
        
        let generator = FileGenerator(filesystem: self.filesystem)
        
        try generator.generateDirectories([
            root,
            sources,
            config
        ])
        
        try generator.generateFiles([
            root + "Info.plist": Plist.frameworkTarget(),
            
        ])
        
        let childModules = try self.delegate?.findChildren(self.spec).map { $0.targetName } ?? []
        
        try generator.generateFiles([
            sources + "Dependencies.swift": SourceFile.dependencies(
                module: self.spec.name,
                features: childModules,
                bundles: bundles,
                resourceBundleId: self.spec.resourceTargetBundleId
            )
        ], overwrite: true)
        
    }
    
    
    func generateResourceTargetFiles() throws {
        let root = self.directory + self.spec.resourceTargetName
        
        let plistPath = root + "Info.plist"
        
        let generator = FileGenerator(filesystem: self.filesystem)
        
        try generator.generateDirectories([
            root
        ])
        
        try generator.generateFiles([
            plistPath: Plist.resourceBundle(
                BUNDLE_IDENTIFIER: self.spec.resourceTargetBundleId,
                PRODUCT_NAME: self.spec.resourceTargetName
            )
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
        try self.generateResourceTargetFiles()
    }
    
    
    func findDependencies() throws -> [Dependency] {
        return try delegate?.findDependencies(self.spec) ?? []
    }
    
    func findBundles() throws -> [ResourceBundle] {
        return try delegate?.findBundles(self.spec) ?? []
    }
    
    
    func generate() throws {
        let project = try self.generateProject()
        
        try project.write(path: self.projectPath)
    }
    
    func generateResourceBundleTarget() throws -> Target {
        
        let targetName = self.spec.resourceTargetName
        
        return Target(
            name: targetName,
            type: .bundle,
            platform: .iOS,
            settings: .init(
                buildSettings: ["INFOPLIST_FILE": "\(targetName)/Info.plist"]
            ),
            sources: [
                TargetSource(path: targetName)
            ],
            dependencies: [],
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
        
        let dependencies = try self.findDependencies()
        
        let targetName = self.spec.targetName
        let testTargetName = self.spec.unitTestTargetName
        
  
        // MARK: - Framework Target
        let frameworkTarget = Target(
            name: targetName,
            type: .framework,
            platform: .iOS,
            settings: .init(
                buildSettings: ["INFOPLIST_FILE": "\(targetName)/Info.plist"]
            ),
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
            settings: .init(
                buildSettings: ["INFOPLIST_FILE": "\(testTargetName)/Info.plist"]
            ),
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
                try generateResourceBundleTarget()
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

