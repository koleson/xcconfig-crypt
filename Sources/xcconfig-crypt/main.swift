import Foundation
import ArgumentParser
import Crypto

struct XCConfigCrypt: ParsableCommand {
    static var configuration = CommandConfiguration(subcommands: [Encrypt.self, Decrypt.self])
    
    //    @Argument(help: "input xcconfig, unencrypted")
    //    var inputFile: String
    //
    //    @Argument(help: "the key with which to encrypt the values")
    //    var key: String
    
    //    mutating func run() throws {
    //        assert(key.count == 32, "Key must be 32 ascii characters")
    //        print("Hello, world! let's do a thing with file \(inputFile)")
    //        let plaintext: Data = "Some Super Secret Message".data(using: String.Encoding.utf8)!
    //        // let keyString = "dm5Eb092Ymk1MEpWZDhvWA=="      // base64 encoded 32-character ASCII
    //
    //        guard let keyData = Data(base64Encoded: key) else {
    //            fatalError("could not base64-decode key string :(")
    //        }
    //
    //        let key = SymmetricKey(data: keyData)
    //        //let key = SymmetricKey(size: .bits256)
    //
    //        do {
    //            // world's crappiest nonce for idemptoency
    //            let nonce = try AES.GCM.Nonce(data: Array(repeating: 0, count: 12))
    //
    //
    //            let sealedBox = try AES.GCM.seal(plaintext, using: key, nonce: nonce)
    //            let recoveredPlaintext = try AES.GCM.open(sealedBox, using: key, authenticating: Data())
    //            let recoveredPlaintextWithoutAAD = try AES.GCM.open(sealedBox, using: key)
    //
    //            //let stuff = try AES.GCM.
    //            guard let sealedBoxCipherText = sealedBox.combined?.base64EncodedString() else {
    //                print("sealedBox = \(sealedBox)")
    //                fatalError("couldn't get a combined ciphertext + nonce from the sealed box")
    //            }
    //
    //            print("cipherText: \(sealedBoxCipherText)")
    //            print("recoveredPlaintext: \(String(describing: String(data: recoveredPlaintext, encoding: .utf8)))")
    //            print("recoveredPlaintextWithoutAAD: \(String(describing: String(data: recoveredPlaintextWithoutAAD, encoding: .utf8)))")
    //        } catch {
    //            // things
    //            print("!!!! something went wrong.")
    //            fatalError()
    //        }
    
}

// encrypt path
extension XCConfigCrypt {
    struct Encrypt: ParsableCommand {
        @Argument(help: "Input file to be encrypted")
        var inputFilename: String
        
        @Argument(help: "the key with which to encrypt the values")
        var key: String
        
        static let KeyValueSeparator = " = "
        
        func run() throws {
            assert(key.count == 32, "Key must be 32 ascii characters")
            print("Hello, world! let's do a thing with file \(inputFilename)")
            let plaintext: Data = "Some Super Secret Message".data(using: String.Encoding.utf8)!
            // let keyString = "dm5Eb092Ymk1MEpWZDhvWA=="      // base64 encoded 32-character ASCII
            
            guard let keyData = Data(base64Encoded: key) else {
                fatalError("could not base64-decode key string :(")
            }
            
            /// basic tests below
            let key = SymmetricKey(data: keyData)
            //let key = SymmetricKey(size: .bits256)
            
            do {
                // world's crappiest nonce for idemptoency
                let nonce = try AES.GCM.Nonce(data: Array(repeating: 0, count: 12))
                
                
                let sealedBox = try AES.GCM.seal(plaintext, using: key, nonce: nonce)
                let recoveredPlaintext = try AES.GCM.open(sealedBox, using: key, authenticating: Data())
                let recoveredPlaintextWithoutAAD = try AES.GCM.open(sealedBox, using: key)
                
                //let stuff = try AES.GCM.
                guard let sealedBoxCipherText = sealedBox.combined?.base64EncodedString() else {
                    print("sealedBox = \(sealedBox)")
                    fatalError("couldn't get a combined ciphertext + nonce from the sealed box")
                }
                
                print("cipherText: \(sealedBoxCipherText)")
                print("recoveredPlaintext: \(String(describing: String(data: recoveredPlaintext, encoding: .utf8)))")
                print("recoveredPlaintextWithoutAAD: \(String(describing: String(data: recoveredPlaintextWithoutAAD, encoding: .utf8)))")
            } catch {
                // things
                print("!!!! something went wrong.")
                fatalError()
            }
            
            /// actual implementation starts below
            guard FileManager.default.fileExists(atPath: inputFilename) else {
                fatalError("could not open file \(inputFilename)")
            }
            
            /// because i'm lazy and RAM is cheap - read whole file in at once then split into lines
            var lines: [String]
            var encryptedLines = [String]()
            do {
                let contents = try String(contentsOfFile: inputFilename)
                lines = contents.components(separatedBy: .newlines)
            } catch {
                fatalError("error reading contents of file \(inputFilename)")
            }
            
            for line in lines {
                // if comment, passthru
                // if not comment, see if there's a single " = " separating key from value, encrypt
                // if not comment or key/value, but whitespace only, passthru
                // if none of those, we can't figure out what's going on - tell user
                
                if line.hasPrefix("//") {
                    // line is a comment - passthru
                    encryptedLines.append(line)
                } else if line.components(separatedBy: Encrypt.KeyValueSeparator).count == 2 {
                    let lineComponents = line.components(separatedBy: " = ")
                    // exactly a key and a value - encrypt value
                    var encryptedLine = lineComponents[0]
                    encryptedLine.append(Encrypt.KeyValueSeparator)
                    let plaintextValue = lineComponents[1]
                    // TODO:  ENCRYPT HERE
                    do {
                        guard let plaintextUTF8Data = plaintextValue.data(using: .utf8) else {
                            fatalError("could not encode value \(plaintextValue) to UTF-8")
                        }
                        
                        let nonce = try AES.GCM.Nonce(data: Array(repeating: 0, count: 12))
                        
                        let sealedBox = try AES.GCM.seal(plaintextUTF8Data, using: key, nonce: nonce)
                        
                        guard let sealedBoxCipherText = sealedBox.combined?.base64EncodedString() else {
                            fatalError("could not get sealed box cipher text for line \(line)")
                        }
                        
                        encryptedLine.append(sealedBoxCipherText)
                    } catch {
                        fatalError("error encrypting line: \(error)\n\noffending line: \(line)")
                    }
                    
                    encryptedLines.append(encryptedLine)
                } else if line.components(separatedBy: Encrypt.KeyValueSeparator).count > 2 {
                    // key/value-ish, but too many key-value separators - cannot intelligently operate on it
                    fatalError("key/value-looking line had multiple assignment operators:\n\n\(line)")
                } else if line.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
                    // line is empty besides whitespace - passthru
                    encryptedLines.append(line)
                } else {
                    fatalError("line was neither a comment nor a key-value pair and was not empty besides whitespace:\n\n\(line))")
                }
            }
            
            let encryptedFile = encryptedLines.joined(separator: "\n")
            print("done processing - output string is:\n\n\(encryptedFile)")
            let encryptedFileData = encryptedFile.data(using: .utf8)
            
            guard FileManager.default.createFile(atPath: inputFilename + ".enc", contents: encryptedFileData) else {
                fatalError("could not create output file")
            }
            
            print("wrote file successfully!")
        }
    }
    
    
}

// decrypt path

extension XCConfigCrypt {
    struct Decrypt: ParsableCommand {
        @Argument(help: "Encrypted file to be decrypted")
        var encryptedFile: String
        
        @Argument(help: "the key with which to decrypt the values")
        var key: String
        
        func run() throws {
            print("hi we are in decrypt path")
            fatalError("bummer, decrypt path not implemented yet")
        }
    }
}

XCConfigCrypt.main()
