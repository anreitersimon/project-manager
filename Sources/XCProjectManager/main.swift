import Foundation
import PathKit
import Commander
import XCProjectManagerCore
import xcproj
import ProjectSpec
import JSONUtilities

let version = "0.1.3"

enum ManagerCommand: String {
    case scaffold = "scaffold"
    case generate = "generate"
}


typealias CommandRunner = (
    _ spec: String,
    _ verbose: Bool,
    _ version: Bool
) -> Void

func run(command: ManagerCommand) ->  CommandRunner {

    return { spec, verbose, version in
        guard !version else {
            print(version)
            exit(EXIT_SUCCESS)
        }
        
        run(command, spec: spec, verbose: verbose)
    }
}

func run(_ command: ManagerCommand, spec: String, verbose: Bool) {

    let logger = Logger(isQuiet: !verbose)
    
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
        let projectGenerator = WorkspaceGenerator(
            spec: spec,
            workspacePath: projectPath + "\(spec.name).xcworkspace",
            makeFilePath: projectPath + "Makefile"
        )
        
        switch command {
        case .generate:
            try projectGenerator.scaffold()
            try projectGenerator.generate()
        case .scaffold:
            try projectGenerator.scaffold()
        }
        
        
    } catch let error as SpecValidationError {
        fatalError(error.description)
    } catch {
        fatalError("Generation failed: \(error.localizedDescription)")
    }
}

let specOption = Option<String>(
    "spec",
    default: "project.yml",
    flag: "s",
    description: "The path to the spec file"
)

let verboseFlag = Flag(
    "verbose",
    default: false,
    description: "Suppress printing of informational and success messages"
)

let versionFlag = Flag(
    "version",
    default: false,
    flag: "v",
    description: "Show version"
)

let group = Group {
    
    $0.addCommand(
        "generate",
        nil,
        command(
            specOption,
            verboseFlag,
            versionFlag,
            run(command: .generate)
        )
    )
    
    $0.addCommand(
        "scaffold",
        nil,
        command(
            specOption,
            verboseFlag,
            versionFlag,
            run(command: .scaffold)
        )
    )
}

group.run(version)
