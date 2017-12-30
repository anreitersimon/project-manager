//
//  ProjectGenerator.swift
//  XCProjectManagerPackageDescription
//
//  Created by Simon Anreiter on 29.12.17.
//

import Foundation
import XcodeGenKit
import ProjectSpec
import JSONUtilities
import PathKit
import Yams
import xcproj

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
    
    func feature(for name: String) -> FeatureSpec? {
        return self.features.first { $0.name == name }
    }
    
    func carthage(for name: String) -> FeatureSpec? {
        return self.features.first { $0.name == name }
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
    
    func generateAppDependencies(_ app: AppSpec) -> (carthage: Set<String>, dependencies: Set<String>) {
        var result = Set<String>(app.carthageDependencies ?? [])
        
        
        let deps = Set<String>(app.dependencies ?? [])
        let subFeatures = deps.flatMap { self.feature(for: $0) }
        
        for f in subFeatures {
            result.formUnion(self.flattenedCarthageDependencies(feature: f))
        }
        
        return (result, deps)
    }
    
}

public struct AppSpec: NamedJSONDictionaryConvertible {
    public let name: String
    public let deploymentTarget: Version?
    
    public let carthageDependencies: [String]?
    public let dependencies: [String]?
    
    public init(name: String, jsonDictionary: JSONDictionary) throws {
        self.name = name
        
        carthageDependencies = jsonDictionary.json(atKeyPath: "carthageDependencies")
        dependencies = jsonDictionary.json(atKeyPath: "dependencies")
        let deploymentTarget: Double? = jsonDictionary.json(atKeyPath: "deploymentTarget")
        self.deploymentTarget = try deploymentTarget.map { try Version($0) }
    }
    
    public var targetName: String {
        return self.name
    }
    
    public var unitTestTargetName: String {
        return "\(self.name)Tests"
    }
    
    public var uiTestTargetName: String {
        return "\(self.name)UI-Tests"
    }
}

public struct FeatureSpec: NamedJSONDictionaryConvertible {

    public let name: String
    
    public let carthageDependencies: [String]?
    public let dependencies: [String]?

    public init(name: String, jsonDictionary: JSONDictionary) throws {
        self.name = name

        carthageDependencies = jsonDictionary.json(atKeyPath: "carthageDependencies")
        dependencies = jsonDictionary.json(atKeyPath: "dependencies")
    }
    
    public init(
        name: String,
        carthageDependencies: [String]  = [],
        dependencies: [String] = []
    ) {
        self.name = name
        self.carthageDependencies = carthageDependencies
        self.dependencies = dependencies
    }

}
public class FeatureGenerator {

    
    public let spec: WorkspaceSpec
    public let logger: Logger
 
    public init(
        logger: Logger,
        spec: WorkspaceSpec
    ) {
        self.logger = logger
        self.spec = spec
    }
    
    func generateAppTarget(app: AppSpec) -> Target {
        
        let (carthage, deps) = self.spec.generateAppDependencies(app)
        
        let carthageDependencies = carthage.map {
            return Dependency(
                type: .carthage,
                reference: $0,
                embed: true,
                link: true,
                implicit: false
            )
        }
        
        let featureDependencies = deps.map {
            return Dependency(
                type: .framework,
                reference: "\($0).framework",
                embed: true,
                link: true,
                implicit: true
            )
        }
        
        var dependencies = carthageDependencies
        dependencies.append(contentsOf: featureDependencies)
        
        return Target(
            name: app.targetName,
            type: .application,
            platform: .iOS,
            deploymentTarget: app.deploymentTarget,
            settings: Settings(
                buildSettings: [:],
                configSettings: [:],
                groups: []
            ),
            configFiles: [:],
            sources: [TargetSource(path: app.targetName)],
            dependencies: dependencies,
            prebuildScripts: [],
            postbuildScripts: [],
            scheme: TargetScheme(
                testTargets: [
                    app.unitTestTargetName,
                    app.uiTestTargetName,
                    ],
                configVariants: [],
                gatherCoverageData: true,
                commandLineArguments: [:]
            ),
            legacy: nil
        )
        
    }
    
    func generateUnitTestTarget(app: AppSpec) -> Target {
        
        let (carthage, deps) = self.spec.generateAppDependencies(app)
        
        let carthageDependencies = carthage.map {
            return Dependency(
                type: .carthage,
                reference: $0,
                embed: false,
                link: true,
                implicit: false
            )
        }
        
        let featureDependencies = deps.map {
            return Dependency(
                type: .framework,
                reference: "\($0).framework",
                embed: true,
                link: true,
                implicit: true
            )
        }
        
        var dependencies = carthageDependencies
        dependencies.append(contentsOf: featureDependencies)
        dependencies.append(Dependency.init(type: .target, reference: app.targetName))
        
        return Target(
            name: app.unitTestTargetName,
            type: .unitTestBundle,
            platform: .iOS,
            deploymentTarget: app.deploymentTarget,
            settings: Settings(
                buildSettings: [:],
                configSettings: [:],
                groups: []
            ),
            configFiles: [:],
            sources: [TargetSource(path: app.unitTestTargetName)],
            dependencies: dependencies,
            prebuildScripts: [],
            postbuildScripts: [],
            scheme: TargetScheme(
                testTargets: [],
                configVariants: [],
                gatherCoverageData: true,
                commandLineArguments: [:]
            ),
            legacy: nil
        )
        
    }
    
    func generateUITestTarget(app: AppSpec) -> Target {
        
        return Target(
            name: app.uiTestTargetName,
            type: .unitTestBundle,
            platform: .iOS,
            deploymentTarget: app.deploymentTarget,
            settings: Settings(
                buildSettings: [:],
                configSettings: [:],
                groups: []
            ),
            configFiles: [:],
            sources: [TargetSource(path: app.uiTestTargetName)],
            dependencies: [Dependency(type: .target, reference: app.targetName)],
            prebuildScripts: [],
            postbuildScripts: [],
            scheme: TargetScheme(
                testTargets: [],
                configVariants: [],
                gatherCoverageData: true,
                commandLineArguments: [:]
            ),
            legacy: nil
        )
        
    }
    
    func createProjectStructure(feature: FeatureSpec, in directory: Path) throws {
        
        let mainTarget = directory + feature.name
        let testTarget = directory + "\(feature.name)Tests"
        
        let directoriesToCreate: [Path] = [
            directory,
            mainTarget,
            testTarget,
        ]
        
        for dir in directoriesToCreate {
            
            if !dir.exists {
                logger.info("Creating \(dir.string)")
                try dir.mkpath()
            }
        }
        
        let plistFile = mainTarget + "Info.plist"
        
        if !plistFile.exists {
            
            let content = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>CFBundleDevelopmentRegion</key>
                <string>$(DEVELOPMENT_LANGUAGE)</string>
                <key>CFBundleExecutable</key>
                <string>$(EXECUTABLE_NAME)</string>
                <key>CFBundleIdentifier</key>
                <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
                <key>CFBundleInfoDictionaryVersion</key>
                <string>6.0</string>
                <key>CFBundleName</key>
                <string>$(PRODUCT_NAME)</string>
                <key>CFBundlePackageType</key>
                <string>FMWK</string>
                <key>CFBundleShortVersionString</key>
                <string>1.0</string>
                <key>CFBundleVersion</key>
                <string>$(CURRENT_PROJECT_VERSION)</string>
                <key>NSPrincipalClass</key>
                <string></string>
            </dict>
            </plist>
            """
            
            logger.info("Creating \(plistFile.string)")
            
            try plistFile.write(content, encoding: .utf8)
        }
        
    }
    
    func createProjectStructure(app: AppSpec, in directory: Path) throws {
        
        let mainTarget = directory + app.name
        let unitTestTarget = directory + app.unitTestTargetName
        let uiTestTarget = directory + app.uiTestTargetName
        
        let directoriesToCreate: [Path] = [
            directory,
            mainTarget,
            unitTestTarget,
            uiTestTarget,
            ]
        
        for dir in directoriesToCreate {
            
            if !dir.exists {
                logger.info("Creating \(dir.string)")
                try dir.mkpath()
            }
        }
        
        let plistFile = mainTarget + "Info.plist"
        
        if !plistFile.exists {
            
            let content = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>CFBundleDevelopmentRegion</key>
                <string>$(DEVELOPMENT_LANGUAGE)</string>
                <key>CFBundleExecutable</key>
                <string>$(EXECUTABLE_NAME)</string>
                <key>CFBundleIdentifier</key>
                <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
                <key>CFBundleInfoDictionaryVersion</key>
                <string>6.0</string>
                <key>CFBundleName</key>
                <string>$(PRODUCT_NAME)</string>
                <key>CFBundlePackageType</key>
                <string>APPL</string>
                <key>CFBundleShortVersionString</key>
                <string>1.0</string>
                <key>CFBundleVersion</key>
                <string>1</string>
                <key>LSRequiresIPhoneOS</key>
                <true/>
                <key>UILaunchStoryboardName</key>
                <string>LaunchScreen</string>
                <key>UIMainStoryboardFile</key>
                <string>Main</string>
                <key>UIRequiredDeviceCapabilities</key>
                <array>
                    <string>armv7</string>
                </array>
                <key>UISupportedInterfaceOrientations</key>
                <array>
                    <string>UIInterfaceOrientationPortrait</string>
                    <string>UIInterfaceOrientationLandscapeLeft</string>
                    <string>UIInterfaceOrientationLandscapeRight</string>
                </array>
                <key>UISupportedInterfaceOrientations~ipad</key>
                <array>
                    <string>UIInterfaceOrientationPortrait</string>
                    <string>UIInterfaceOrientationPortraitUpsideDown</string>
                    <string>UIInterfaceOrientationLandscapeLeft</string>
                    <string>UIInterfaceOrientationLandscapeRight</string>
                </array>
            </dict>
            </plist>
            """
            
            logger.info("Creating \(plistFile.string)")
            
            try plistFile.write(content, encoding: .utf8)
        }
        
    }
    
    public func generate(directory: Path) throws {
        
        var refs: [XCWorkspace.Data.FileRef] = self.spec.files?
            .map { .other(location: "group:\($0)") } ?? []
        
        for feature in self.spec.features {
            
            let featureDir = directory + feature.name
            let projectDir = featureDir + "\(feature.name).xcodeproj"
            
            logger.info("⚙️ [\(feature.name)] Creating directories...")
            
            try self.createProjectStructure(feature: feature, in: featureDir)
            
            let project = try self.generateProject(feature: feature, in: featureDir)
            
            refs.append(.other(location: "group:\(feature.name)/\(feature.name).xcodeproj"))
            
            try project.write(path: projectDir, override: true)
        }
        
        for app in self.spec.apps {
            let appDir = directory + app.name
            let projectDir = appDir + "\(app.name).xcodeproj"
            
            logger.info("⚙️ [\(app.name)] Creating directories...")
            
            try self.createProjectStructure(app: app, in: appDir)
            
            let project = try self.generateProject(app: app, in: appDir)
            
            refs.append(.other(location: "group:\(app.name)/\(app.name).xcodeproj"))
            
            try project.write(path: projectDir, override: true)
        }
        
        let workSpace = XCWorkspace(
            data: .init(
                references: refs
            )
        )
        
        logger.info("⚙️ Generating workspace...")
        
        try workSpace.write(path: directory + "\(self.spec.name).xcworkspace", override: true)
        
    }
    
    
    func generateProject(app: AppSpec, in directory: Path) throws -> XcodeProj {
        let spec = ProjectSpec(
            basePath: directory,
            name: app.name,
            configs: [
                Config(name: "Debug", type: .debug),
                Config(name: "Distribution", type: .release),
                Config(name: "Release", type: .release),
            ],
            targets: [
                self.generateAppTarget(app: app),
                self.generateUnitTestTarget(app: app),
                self.generateUITestTarget(app: app)
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
        
        return try ProjectGenerator(spec: spec).generateProject()
    }
    
    func generateProject(feature: FeatureSpec, in directory: Path) throws -> XcodeProj {
        
        let carthage: [JSONDictionary] = feature.carthageDependencies?
            .map { ["carthage": $0]  } ?? []
        
        var dependencies: [JSONDictionary] = feature.dependencies?
            .map { [
                "framework": "\($0).framework",
                "implicit": true
                ] } ?? []
        
        dependencies.append(contentsOf: carthage)
        
        let targetName = feature.name
        let testTargetName = "\(feature.name)Tests"
        
        let specJSON: JSONDictionary = [
            "name": feature.name,
            "options": [
                "bundleIdPrefix": "at.imobility",
                "carthageBuildPath": "../Carthage/Build",
                "createIntermediateGroups": true,
            ],
            "configs": [
                "Debug": "debug",
                "Distribution": "release",
                "Release": "release",
            ],
            "platform": "iOS",
            "deploymentTarget": 9.0,
            "targets": [
                targetName: [
                    "type": "framework",
                    "platform": "iOS",
                    "deploymentTarget": 9.0,
                    "sources": [targetName],
                    "settings": [:],
                    "dependencies": dependencies,
                    "scheme": [
                        "testTargets": [testTargetName]
                    ]
                ],
                testTargetName: [
                    "type": "bundle.unit-test",
                    "platform": "iOS",
                    "sources": [testTargetName]
                ]
            ]
        ]
        
        let spec = try ProjectSpec(
            basePath: directory,
            jsonDictionary: specJSON
        )
        
        logger.info("📋 [\(feature.name)] Generating spec:\n  \(spec)")
    
        let generator = ProjectGenerator(
            spec: spec
        )
        
        return try generator.generateProject()
    }
    
    
    
}
