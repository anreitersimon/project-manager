import Foundation
import PathKit
import Commander
import XCProjectManagerCore
import xcproj
import ProjectSpec
import JSONUtilities

let version = "0.0.1"

func generate(spec: String, outputDir: String, isQuiet: Bool, justVersion: Bool) {
    if justVersion {
        print(version)
        exit(EXIT_SUCCESS)
    }
    
    let logger = Logger(isQuiet: isQuiet)
    
    func fatalError(_ message: String) -> Never {
        logger.error(message)
        exit(1)
    }
    
    let specPath = Path(spec).absolute()

    if !specPath.exists {
        fatalError("No project spec found at \(specPath.absolute())")
    }
    
    let spec: WorkspaceSpec
    
    do {
        spec = try WorkspaceSpec(path: specPath)
    } catch let error as JSONUtilities.DecodingError {
        fatalError("Parsing spec failed: \(error.description)")
    } catch {
        fatalError("Parsing spec failed: \(error.localizedDescription)")
    }


    let projectPath = specPath.parent()
    
    do {
        
        
        let projectGenerator = FeatureGenerator(logger: logger, spec: spec)
        
        try projectGenerator.generate(directory: projectPath)
        
    } catch let error as SpecValidationError {
        fatalError(error.description)
    } catch {
        fatalError("Generation failed: \(error.localizedDescription)")
    }
}

command(
    Option<String>(
        "spec",
        default: "project.yml",
        flag: "s",
        description: "The path to the spec file"
    ),
    Option<String>(
        "output",
        default: "",
        flag: "o",
        description: "Output Path"
    ),
    Flag(
        "quiet",
        default: false,
        flag: "q",
        description: "Suppress printing of informational and success messages"
    ),
    Flag(
        "version",
        default: false,
        flag: "v",
        description: "Show XcodeGen version"
    ),
    generate
    ).run(version)
