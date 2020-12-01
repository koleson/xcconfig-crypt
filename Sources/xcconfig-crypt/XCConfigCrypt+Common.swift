//
//  File.swift
//  
//
//  Created by Kiel Oleson on 11/30/20.
//

import Foundation

extension XCConfigCrypt {
    static func write(lines: [String], toFilename filename: String) {
        let combinedFile = lines.joined(separator: "\n")
        let combinedFileData = combinedFile.data(using: .utf8)
        
        guard FileManager.default.createFile(atPath: filename, contents: combinedFileData) else {
            fatalError("could not create output file \(filename)")
        }
    }
    
    static func lines(fromFileNamed filename: String) throws -> [String] {
        /// because i'm lazy and RAM is cheap - read whole file in at once then split into lines
        
        guard FileManager.default.fileExists(atPath: filename) else {
            fatalError("could not open file \(filename)")
        }
        
        var lines: [String]
        
        do {
            let contents = try String(contentsOfFile: filename)
            lines = contents.components(separatedBy: .newlines)
        } catch {
            fatalError("error reading contents of file \(filename)")
        }
        
        return lines
    }
    
    typealias ValueModificationBlock = (String) -> (String)
    
    /// TODO:  convert to `throws`?
    static func process(lines: [String], withValueModificationBlock modificationBlock: ValueModificationBlock) -> [String] {
        // TODO:  move processing in here
        var processedLines = [String]()
        
        for line in lines {
            // if comment, passthru
            // if not comment, see if there's a single " = " separating key from value, encrypt
            // if not comment or key/value, but whitespace only, passthru
            // if none of those, we can't figure out what's going on - tell user
            
            if line.hasPrefix("//") {
                // line is a comment - passthru
                processedLines.append(line)
            } else if line.components(separatedBy: Encrypt.KeyValueSeparator).count == 2 {
                let lineComponents = line.components(separatedBy: " = ")
                // exactly a key and a value - encrypt value
                var processedLine = lineComponents[0]
                processedLine.append(Encrypt.KeyValueSeparator)
                let unprocessedValue = lineComponents[1]
                // TODO:  PROCESS HERE
                let processedValue = modificationBlock(unprocessedValue)
                
                processedLine.append(processedValue)
                processedLines.append(processedLine)
            } else if line.components(separatedBy: Encrypt.KeyValueSeparator).count > 2 {
                // key/value-ish, but too many key-value separators - cannot intelligently operate on it
                fatalError("key/value-looking line had multiple assignment operators:\n\n\(line)")
            } else if line.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
                // line is empty besides whitespace - passthru
                processedLines.append(line)
            } else {
                fatalError("line was neither a comment nor a key-value pair and was not empty besides whitespace:\n\n\(line))")
            }
        }
        
        return processedLines
    }
}
