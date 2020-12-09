import Foundation
import ArgumentParser
import Crypto

// encrypt path
extension XCConfigCrypt {
    struct Encrypt: ParsableCommand {
        @Argument(help: "Input file to be encrypted")
        var inputFilename: String
        
        @Option(name: .shortAndLong, help: "the key with which to encrypt the values")
        var key: String
        
        @Flag(name: .shortAndLong, help: "trim the key string to the first 256 bits if it is longer than 256 bits")
        var trimKey: Bool = false
        
        static let KeyValueSeparator = " = "
        
        func run() throws {
            let parsedKey = XCConfigCrypt.parseKey(forString: key, trim: trimKey)
            
            var lines: [String]
            do {
                lines = try XCConfigCrypt.lines(fromFileNamed: inputFilename)
                let contents = try String(contentsOfFile: inputFilename)
                lines = contents.components(separatedBy: .newlines)
            } catch {
                fatalError("error reading contents of file \(inputFilename)")
            }
            
            let encryptedLines = XCConfigCrypt.process(lines: lines) { (value) -> (String) in
                do {
                    guard let plaintextUTF8Data = value.data(using: .utf8) else {
                        fatalError("could not encode value \(value) to UTF-8")
                    }
                    
                    let nonce = try AES.GCM.Nonce(data: Array(repeating: 0, count: 12))
                    
                    let sealedBox = try AES.GCM.seal(plaintextUTF8Data, using: parsedKey, nonce: nonce)
                    
                    guard let sealedBoxCipherText = sealedBox.combined?.base64EncodedString() else {
                        fatalError("could not get sealed box cipher text for value \(value)")
                    }
                    
                    return sealedBoxCipherText
                } catch {
                    fatalError("error encrypting line: \(error)\n\noffending value: \(value)")
                }
            }
            let encryptedFilename = inputFilename + ".enc"
            XCConfigCrypt.write(lines: encryptedLines, toFilename: encryptedFilename)
            
            print("wrote file \(encryptedFilename) successfully!")
        }
    }
    
    
}

// decrypt path
extension XCConfigCrypt {
    struct Decrypt: ParsableCommand {
        @Argument(help: "Encrypted file to be decrypted")
        var encryptedFilename: String
        
        @Option(name: .shortAndLong, help: "the key with which to decrypt the values")
        var key: String
        
        @Flag(name: .shortAndLong, help: "trim the key string to the first 256 bits if it is longer than 256 bits")
        var trimKey: Bool = false
        
        func run() throws {
            print("decrypting file \(encryptedFilename)")
            
            do {
                let parsedKey = XCConfigCrypt.parseKey(forString: key, trim: trimKey)
                
                let lines = try XCConfigCrypt.lines(fromFileNamed: encryptedFilename)
                let decryptedLines = XCConfigCrypt.process(lines: lines) { (encryptedValue) -> (String) in
                    do {
                        guard let encryptedData = Data(base64Encoded: encryptedValue) else {
                            fatalError("couldn't base64 decode encrypted data in encrypted value \(encryptedValue)")
                        }
                        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
                        let recoveredData = try AES.GCM.open(sealedBox, using: parsedKey, authenticating: Data())
                        guard let recoveredPlaintext = String(data: recoveredData, encoding: .utf8) else {
                            fatalError("could not recover utf8 text from decrypted data")
                        }
                        return recoveredPlaintext
                    } catch {
                        fatalError("Couldn't decrypt data")
                    }
                }
                
                // scripts will need to move this into place as the actual file name
                XCConfigCrypt.write(lines: decryptedLines, toFilename: encryptedFilename + ".decrypted")
            } catch {
                fatalError("could not read encrypted file")
            }
        }
    }
}


extension XCConfigCrypt {
    static func parseKey(forString string: String, trim: Bool = false) -> SymmetricKey {
        // TODO:  extract trim / parse key
        guard (trim && string.count >= 32) || (string.count == 32) else {
            fatalError("key must be 32 characters/256 bits exactly (or more if --trim-key specified)")
        }
        
        let trimmedKey: String
        if trim {
            trimmedKey = String(string.prefix(32))
        } else {
            trimmedKey = string
        }
        
        guard let keyData = trimmedKey.data(using: .utf8) else {
            fatalError("could not decode key string :(")
        }
        
        let key = SymmetricKey(data: keyData)
        
        return key
    }
}
