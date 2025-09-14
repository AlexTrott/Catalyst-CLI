import Foundation
import Files

public extension FileManager {

    func createDirectoryIfNeeded(at path: String) throws {
        if !fileExists(atPath: path) {
            try createDirectory(
                atPath: path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }

    func createFileIfNeeded(at path: String, contents: String) throws {
        let directoryPath = (path as NSString).deletingLastPathComponent
        try createDirectoryIfNeeded(at: directoryPath)

        if !fileExists(atPath: path) {
            createFile(atPath: path, contents: contents.data(using: .utf8), attributes: nil)
        }
    }

    func isDirectory(at path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    func copyDirectory(from sourcePath: String, to destinationPath: String) throws {
        if fileExists(atPath: destinationPath) {
            try removeItem(atPath: destinationPath)
        }

        try copyItem(atPath: sourcePath, toPath: destinationPath)
    }

    func findFile(named fileName: String, in directory: String) -> String? {
        guard let enumerator = enumerator(atPath: directory) else { return nil }

        for case let file as String in enumerator {
            if file.hasSuffix(fileName) {
                return (directory as NSString).appendingPathComponent(file)
            }
        }
        return nil
    }

    func findWorkspace(in directory: String = ".") -> String? {
        let currentPath = directory == "." ? currentDirectoryPath : directory

        guard let contents = try? contentsOfDirectory(atPath: currentPath) else {
            return nil
        }

        for item in contents {
            if item.hasSuffix(".xcworkspace") {
                return (currentPath as NSString).appendingPathComponent(item)
            }
        }

        return nil
    }

    func findProject(in directory: String = ".") -> String? {
        let currentPath = directory == "." ? currentDirectoryPath : directory

        guard let contents = try? contentsOfDirectory(atPath: currentPath) else {
            return nil
        }

        for item in contents {
            if item.hasSuffix(".xcodeproj") {
                return (currentPath as NSString).appendingPathComponent(item)
            }
        }

        return nil
    }

    func validateModuleName(_ name: String) -> Bool {
        let pattern = "^[A-Za-z][A-Za-z0-9_]*$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: name.utf16.count)
        return regex?.firstMatch(in: name, options: [], range: range) != nil
    }

    func sanitizeFileName(_ fileName: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
        return fileName
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_")
    }
}

public extension Folder {

    func createSubfolderIfNeeded(named name: String) throws -> Folder {
        if let existingFolder = try? subfolder(named: name) {
            return existingFolder
        }
        return try createSubfolder(named: name)
    }

    func createFileIfNeeded(named name: String, contents: String) throws -> File {
        if let existingFile = try? file(named: name) {
            try existingFile.write(contents)
            return existingFile
        }
        return try createFile(named: name, contents: Data(contents.utf8))
    }

    func findFile(named fileName: String, recursive: Bool = true) -> File? {
        if let file = try? file(named: fileName) {
            return file
        }

        if recursive {
            for subfolder in subfolders {
                if let file = subfolder.findFile(named: fileName, recursive: true) {
                    return file
                }
            }
        }

        return nil
    }

    func isEmpty() -> Bool {
        return files.count() == 0 && subfolders.count() == 0
    }
}