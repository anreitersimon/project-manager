//
//  SourceFile.swift
//  XCProjectManagerCore
//
//  Created by Simon Anreiter on 02.01.18.
//

import Foundation

class SourceFile {
    
    
    static func dependencies(
        module: String,
        features: [String],
        bundles: [String],
        resourceBundleId: String?
    ) -> Data {
        let name = "\(module)DependenciesProtocol"
        
        let modules = features.map { $0 }
        
        var imports = ["Foundation"]
        imports.append(contentsOf: modules)
        
        let resourcesDeclaration = resourceBundleId.map { _ in
            return """
                public static var resources: Bundle? {
                    return Bundle.main
                        .url(forResource: "\(module)Resources", withExtension: "bundle", subdirectory: nil)
                        .flatMap { Bundle(url: $0) }
                }
            """
        }
        
        return """
            \(imports.map { "import \($0)" }.joined(separator: "\n"))
            
            public protocol \(name) {
            
            }
            
            public final class \(module)Description {
            
                public static var features: [Any.Type] {
                    return [
                        \(modules.map { "\($0)Description.self" }.joined(separator: ",\n          "))
                    ]
                }
            
                public static var bundles: [Bundle] {
                    return [
                    \(modules.map { "\($0)Description.resources" }.joined(separator: ",\n          "))
                    ].flatMap { $0 }
                }
            
            \(resourcesDeclaration ?? "")
            }
            
            """.data(using: .utf8)!
    }
    
    static func appdelegate() -> Data {
        return """
            import UIKit

            @UIApplicationMain
            class AppDelegate: UIResponder, UIApplicationDelegate {

                var window: UIWindow?


                func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
                    // Override point for customization after application launch.
                    return true
                }

            }

            """.data(using: .utf8)!
    }
    
    static func unitTest(name: String, dependency: DependencyDeclaration) -> Data {
        
        let deps = Array(dependency.frameworks.keys)
        
        let imports = [
            ["import XCTest"],
            ["@testable import \(name)"],
            deps.map { "@testable import \($0)" }
        ].flattened()
        .joined(separator: "\n")
        
        
        let tests: [String] = deps.flatMap {
            return [
                "func test\($0)Resources() {",
                "\tlet _ = \($0)Description.resources",
                "}"
            ]
        }
        
        return """
            \(imports)
            
            class \(name)Tests: XCTestCase {
            
                func testDescription() {
                    print(\(name)Description.features)
                }
            
            \(tests.indent().joined(separator: "\n"))
            }
            """.data(using: .utf8)!
    }
    
    static func uiTest(app: AppSpec) -> Data {
        return """
            import XCTest
            @testable import \(app.targetName)
            
            class \(app.targetName)UITests: XCTestCase {
            
            }
            """.data(using: .utf8)!
    }
}
