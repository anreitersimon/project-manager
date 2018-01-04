//
//  FileGenerator.swift
//  XCProjectManagerCore
//
//  Created by Simon Anreiter on 02.01.18.
//

import Foundation
import PathKit

protocol FileSystem {
    func mkPath(_ path: Path) throws
    
    func exists(_ path: Path) -> Bool
    
    func write(_ data: Data, to path: Path) throws
}

class DefaultFileSystem: FileSystem {
    func mkPath(_ path: Path) throws {
        try path.mkpath()
    }
    
    func exists(_ path: Path) -> Bool {
        return path.exists
    }
    
    func write(_ data: Data, to path: Path) throws {
        try path.write(data)
    }
}

class FileGenerator {
    
    let filesystem: FileSystem
    
    init(filesystem: FileSystem) {
        self.filesystem = filesystem
    }
    
    func generateDirectories(_ directories: [Path]) throws {
        
        for directory in directories where !filesystem.exists(directory) {
            try filesystem.mkPath(directory)
        }
        
    }
    
    func generateFiles(_ files: [Path: Data], overwrite: Bool = false) throws {
        
        let predicate: (Path) -> Bool = { path in
            if !self.filesystem.exists(path) { return true }
            
            return overwrite
        }
        
        for (path, contents) in files where predicate(path) {
            try filesystem.write(contents, to: path)
        }
        
    }
}
