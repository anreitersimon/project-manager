import Foundation
import XcodeGenKit
import ProjectSpec
import JSONUtilities
import PathKit
import Yams
import xcproj

public protocol FrameworkProjectGeneratorDelegate: class {
    func dependencies(of framework: FrameworkSpec) throws -> DependencyDeclaration
}


public class FrameworkProjectGenerator {
    
    public typealias Delegate = FrameworkProjectGeneratorDelegate
    
    public let spec: FrameworkSpec
    public let projectPath: Path
    weak var delegate: Delegate?
    
    var _dependencies: DependencyDeclaration?
    
    var dependencies: DependencyDeclaration {
        if let d = _dependencies {
            return d
        }
        
        guard let d = self.delegate else { return DependencyDeclaration()  }
        
        let result = (try? d.dependencies(of: self.spec)) ?? DependencyDeclaration()
        
        _dependencies = result
        
        return result
    }
    
    var testDependencies: [Dependency] {
        
        var result = self.dependencies
        
        result.carthage.formUnion(self.spec.carthage ?? [])
        
        var dependencies = result.generateDependencies(embed: true, link: true, implicit: true)
        
        dependencies.append(
            Dependency(type: .target, reference: self.spec.targetName, embed: true)
        )
        
        return dependencies
    }
    
    
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
    
    
    public func generateTargets() throws -> [Target] {
        return [
            try self.generateFrameworkTarget(),
            try self.generateTestTarget()
        ].flatMap { $0 }
    }
    
    func generateMainTargetFiles() throws {
        let root = self.directory + self.spec.targetName
        let sources = root + "Sources"
        let config = root + "Config"
        
        let bundles = Array(self.dependencies.bundles.keys)
        let childModules = Array(self.dependencies.frameworks.keys)
        
        let generator = FileGenerator(filesystem: self.filesystem)
        
        try generator.generateDirectories([
            root,
            sources,
            config
        ])
        
        try generator.generateFiles([
            root + "Info.plist": Plist.frameworkTarget(),
        ])
    
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
        let config = root + "Config"
        
        let generator = FileGenerator(filesystem: self.filesystem)
        
        try generator.generateDirectories([
            root,
            config
        ])
        
        try generator.generateFiles([
            root + "Info.plist": Plist.frameworkTargetTests()
        ])
        
        try generator.generateFiles([
            root + "\(self.spec.targetName)Tests.swift": SourceFile.unitTest(name: self.spec.targetName, dependency: self.dependencies)
        ], overwrite: true)
    }
    
    func scaffold() throws {
        try self.generateMainTargetFiles()
        try self.generateTestTargetFiles()
        try self.generateResourceTargetFiles()
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
                gatherCoverageData: false,
                commandLineArguments: [:]
            ),
            legacy: nil
        )
    }
    
    func generateFrameworkTarget() throws -> Target {
        
        let targetName = self.spec.targetName
        
        let dependencies = self.dependencies.generateDependencies(embed: false, link: true, implicit: true)
        
        return Target(
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
            postbuildScripts: [ /* generateFrameworkCarthageScript(dependencies) */],
            scheme: TargetScheme(
                testTargets: [self.spec.unitTestTargetName],
                gatherCoverageData: true,
                commandLineArguments: [:]
            ),
            legacy: nil
        )
    }
    
    
    func generateFrameworkCarthageScript(_ dependencies: [Dependency]) -> BuildScript {
        let carthageBuildPath = "../Carthage/Build"
        
        let carthageFrameworksToEmbed = dependencies
            .filter { $0.type == .carthage }
            .map { $0.reference }
            .sorted()
        
        let inputPaths = carthageFrameworksToEmbed
            .map { "$(SRCROOT)/\(carthageBuildPath)/iOS/\($0)\($0.contains(".") ? "" : ".framework")" }
        let outputPaths = carthageFrameworksToEmbed
            .map { "$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/\($0)\($0.contains(".") ? "" : ".framework")" }
        
        
        return  BuildScript(
            script: .script("""
            /usr/local/bin/carthage copy-frameworks
            """),
            name: "Carthage",
            inputFiles: inputPaths,
            outputFiles: outputPaths,
            shell: nil,
            runOnlyWhenInstalling: false
        )
    }
    
    func generateTestTarget() throws -> Target {
        
        let testTargetName = self.spec.unitTestTargetName
        
        return Target(
            name: testTargetName,
            type: .unitTestBundle,
            platform: .iOS,
            settings: .init(
                buildSettings: ["INFOPLIST_FILE": "\(testTargetName)/Info.plist"]
            ),
            sources: [
                TargetSource(path: testTargetName)
            ],
            dependencies: testDependencies,
            prebuildScripts: [],
            postbuildScripts: [generateFrameworkCarthageScript(self.testDependencies)],
            scheme: TargetScheme(
                testTargets: [],
                gatherCoverageData: false,
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
            targets: try generateTargets(),
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

