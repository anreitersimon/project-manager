//
//  DependencyDeclaration.swift
//  XCProjectManagerCore
//
//  Created by Simon Anreiter on 04.01.18.
//

import Foundation
import ProjectSpec

public struct DependencyDeclaration {
    public var carthage: Set<String>
    public var frameworks: [String: FrameworkSpec]
    public var bundles: [String: ResourceBundle]
    
    public init(
        carthage: Set<String> = [],
        frameworks: [String: FrameworkSpec] = [:],
        bundles: [String: ResourceBundle] = [:]
        ) {
        self.carthage = carthage
        self.frameworks = frameworks
        self.bundles = bundles
    }
    
    public init(
        carthage: Set<String>,
        frameworkList: [FrameworkSpec],
        bundleList: [ResourceBundle]
        ) {
        self.carthage = carthage
        self.frameworks = Dictionary(frameworkList.map { ($0.name, $0) }) { _, new in new }
        self.bundles = Dictionary(bundleList.map { ($0.name, $0) }) { _, new in new }
    }
    
    public static func + (lhs: DependencyDeclaration, rhs: DependencyDeclaration) -> DependencyDeclaration {
        
        return DependencyDeclaration(
            carthage: lhs.carthage.union(rhs.carthage),
            frameworks: lhs.frameworks.merged(rhs.frameworks),
            bundles: lhs.bundles.merged(rhs.bundles)
        )
    }
    
    public static func += (lhs: inout DependencyDeclaration, rhs: DependencyDeclaration) {
        lhs = lhs + rhs
    }
    
    public func generateCarthage(embed: Bool, link: Bool) -> [Dependency] {
        return self.carthage
            .map {
                Dependency(
                    type: .carthage,
                    reference: $0,
                    embed: embed,
                    link: link,
                    implicit: false
                )
        }
    }
    
    public func generateFrameworks(embed: Bool, link: Bool, implicit: Bool) -> [Dependency] {
        return self.frameworks.keys
            .map {
                Dependency(
                    type: .framework,
                    reference: "\($0).framework",
                    embed: embed,
                    link: link,
                    implicit: implicit
                )
        }
    }
    
    public func generateBundles(embed: Bool, implicit: Bool) -> [Dependency] {
        return self.bundles.keys
            .map {
                Dependency(
                    type: .resourceBundle,
                    reference: "\($0).bundle",
                    embed: embed,
                    link: false,
                    implicit: implicit
                )
        }
    }
    
    
    public func generateDependencies(embed: Bool, link: Bool, implicit: Bool) -> [Dependency] {
        return [
            generateFrameworks(embed:embed, link: link, implicit: implicit),
            generateCarthage(embed:embed, link: link),
            generateBundles(embed:embed, implicit: implicit)
        ].flatMap { $0 }
    }
}
