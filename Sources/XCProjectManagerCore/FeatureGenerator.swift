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
    public let features: [FeatureSpec]
    
    public init(jsonDictionary: JSONDictionary) throws {
        name = try jsonDictionary.json(atKeyPath: "name")
        files = jsonDictionary.json(atKeyPath: "files")
        features = try jsonDictionary.json(atKeyPath: "features")
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
        
        
        let workSpace = XCWorkspace(
            data: .init(
                references: refs
            )
        )
        
        logger.info("⚙️ Generating workspace...")
        
        try workSpace.write(path: directory + "\(self.spec.name).xcworkspace", override: true)
        
        
    }
    
    func generateProject(feature: FeatureSpec, in directory: Path) throws -> XcodeProj {
        
        let carthage: [JSONDictionary] = feature.carthageDependencies?
            .map { ["carthage": $0]  } ?? []
        
        var dependencies: [JSONDictionary] = feature.dependencies?
            .map { [
                "framework": $0,
                "implicit": true
                ] } ?? []
        
        dependencies.append(contentsOf: carthage)
        
        let targetName = feature.name
        let testTargetName = "\(feature.name)Tests"
        
        let specJSON: JSONDictionary = [
            "name": feature.name,
            "options": [
                "bundleIdPrefix": "at.imobility",
                "carthageBuildPath": "${SRCROOT}/../Carthage/Build/iOS/",
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
