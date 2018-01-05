import Foundation
import XcodeGenKit
import ProjectSpec
import JSONUtilities
import PathKit
import Yams
import xcproj

public protocol AppProjectGeneratorDelegate: class {
    func dependencies(of app: AppSpec) throws -> DependencyDeclaration
}

public class AppProjectGenerator {
    public typealias Delegate = AppProjectGeneratorDelegate
    
    public let spec: AppSpec
    public let projectPath: Path
    
    weak var delegate: Delegate?
    
    private var _dependencies: DependencyDeclaration?
    
    var dependencies: DependencyDeclaration {
        if let d = _dependencies {
            return d
        }
        
        guard let d = self.delegate else { return DependencyDeclaration()  }
        
        let result = (try? d.dependencies(of: self.spec)) ?? DependencyDeclaration()
        
        _dependencies = result
        
        return result
    }
    
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
    
    
    
    public func generateTargets() throws -> [Target] {
        return [
            try self.generateAppTarget(),
            try self.generateUnitTestTarget(),
            try self.generateUITestTarget(),
        ].flatMap { $0 }
    }
    
    
    func generateMainTargetFiles() throws {
        let root = self.directory + self.spec.targetName
        let sources = root + "Sources"
        let resources = root + "Resources"
        let config = root + "Config"
        
        let generator = FileGenerator(filesystem: self.filesystem)
      
        
        let bundles = Array(self.dependencies.bundles.keys)
        let childModules = Array(self.dependencies.frameworks.keys)
        
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
        

        try generator.generateFiles([
            root + "\(self.spec.name)UITests.swift": SourceFile.uiTest(app: self.spec)
        ], overwrite: true)
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
        
        try generator.generateFiles([
            root + "\(self.spec.name)Tests.swift": SourceFile.unitTest(name: self.spec.name, dependency: self.dependencies)
        ], overwrite: true)
        
        
        
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

        let dependencies = self.dependencies.generateDependencies(embed: true, link: true, implicit: true)
        
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
        
        return Target(
            name: self.spec.unitTestTargetName,
            type: .unitTestBundle,
            platform: .iOS,
            settings: .init(
                buildSettings: [
                    "INFOPLIST_FILE": "\(self.spec.unitTestTargetName)/Info.plist",
                    "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/\(self.spec.targetName).app/\(self.spec.targetName)"
                ]
            ),
            sources: [
                TargetSource(path: self.spec.unitTestTargetName)
            ],
            dependencies: [Dependency(type: .target, reference: self.spec.targetName)],
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
    
    func generateUITestTarget() throws -> Target {
        
        
        return Target(
            name: self.spec.uiTestTargetName,
            type: .uiTestBundle,
            platform: .iOS,
            settings: .init(
                buildSettings: [
                    "INFOPLIST_FILE": "\(self.spec.uiTestTargetName)/Info.plist",
                    "TEST_TARGET_NAME": self.spec.targetName
                ]
            ),
            sources: [
                TargetSource(path: self.spec.uiTestTargetName)
            ],
            dependencies: [
                Dependency(type: .target, reference: self.spec.targetName)
            ],
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
    
}


