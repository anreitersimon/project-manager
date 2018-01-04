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

                func applicationWillResignActive(_ application: UIApplication) {
                    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
                    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
                }

                func applicationDidEnterBackground(_ application: UIApplication) {
                    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
                    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
                }

                func applicationWillEnterForeground(_ application: UIApplication) {
                    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
                }

                func applicationDidBecomeActive(_ application: UIApplication) {
                    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
                }

                func applicationWillTerminate(_ application: UIApplication) {
                    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
                }


            }

            """.data(using: .utf8)!
    }
}
