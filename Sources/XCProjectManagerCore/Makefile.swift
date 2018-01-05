//
//  Makefile.swift
//  XCProjectManagerCore
//
//  Created by Simon Anreiter on 05.01.18.
//

import Foundation
import ProjectSpec

extension Collection {
    var only: Element? {
        if self.count == 1 {
            return self.first
        } else {
            return nil
        }
    }
}

extension Array where Element == [String] {
    
    func flattened() -> [String] {
        return flatMap { $0 }
    }
}

extension Array where Element == String {
    public func indent(_ value: String = "\t") -> [String] {
        return self.map { "\(value)\($0)"  }
    }
    
}

class Makefile {
    
    enum Error: Swift.Error {
        case noTargets
    }

    
    static func  function(_ name: String, _ body: () -> [String]) -> [String] {
        return [
            ["\(name):"],
            body().indent(),
            ].flatMap { $0 }
        
    }

    static func testFunction() -> [String] {
        return function("test") {
            return [
                ["bundle exec fastlane scan\\"],
                [
                    "--scheme $(SCHEME)\\",
                    "--destination $(DESTINATION)\\",
                    "--only_testing $(TEST_SCHEME)\\",
                    "--derived_data_path $(DERIVED_DATA_PATH)\\",
                    "--output_types html,junit\\",
                    "--output_files $(TEST_SCHEME).html,$(TEST_SCHEME).xml"
                ].indent()
                ].flattened()
        }
    }
    
    public static func generate(_ targets: [Target]) throws -> Data {
        
        let targets = targets
            .filter { $0.type.isApp || $0.type.isFramework }
        
        let apps = targets.filter { $0.type.isApp }
        let frameworks = targets.filter { $0.type.isFramework }
        
        guard let defaultTarget = apps.first ?? frameworks.first else {
            throw Makefile.Error.noTargets
        }
        
        let targetAndTestTargets = targets.map { ($0, $0.scheme?.testTargets ?? []) }

        
        let testAllFunction = function("test-all")  {
            targets.map {  "\"$(MAKE)\" test-\($0.name.lowercased())" }
        }
        
        func runTest(_ name: String, target: String, testScheme: String) -> [String] {
            return function(name) { ["""
                TARGET=\(target) TEST_SCHEME=\(testScheme) "$(MAKE)" test
                """] }
        }
        
        func testDeclarations() -> [String] {
            return targetAndTestTargets
                .flatMap { target, testTargets -> [String] in
                    let testTarget = "test-\(target.name.lowercased())"
                    
                    if let only = testTargets.only {
                        return runTest(testTarget, target: target.name, testScheme: only)
                    } else {
                        
                        let runTargetDeclarations = testTargets
                            .map { "\"$(MAKE)\" run-\($0.lowercased())" }
                        
                        let runAll = function(testTarget) {
                            runTargetDeclarations
                        }
                        
                        let funcs = testTargets
                            .flatMap { testTarget in
                                runTest(
                                    "run-\(testTarget.lowercased())",
                                    target: target.name,
                                    testScheme: testTarget
                                )
                            }
                        
                        return [runAll, funcs].flatMap { $0 }

                    }
                    
            }
        }
        
        return """
            SCHEME ?= $(TARGET)
            TARGET ?= Wegfinder
            TEST_SCHEME ?= WegfinderTests
            PLATFORM ?= iOS
            OS ?= 11.2
            DERIVED_DATA_PATH ?= $(HOME)/Library/Caches/ch.swift.mobilecity_beta.ui-tests

            
            ifeq ($(PLATFORM),iOS)
                DESTINATION ?= 'platform=iOS Simulator,name=iPhone 8,OS=$(OS)'
            endif
            
            \(testAllFunction.joined(separator: "\n"))
            
            \(testDeclarations().joined(separator: "\n"))
            
            \(testFunction().joined(separator: "\n"))
            
            
            
            """.data(using: .utf8)!
        
        
        
    }
    
}
