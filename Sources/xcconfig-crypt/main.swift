import Foundation
import ArgumentParser
import Crypto

struct Encrypt: ParsableCommand {
    @Argument(help: "input xcconfig, unencrypted")
    var inputFile: String
    
    @Argument(help: "the key with which to encrypt the values")
    var key: String
    
    mutating func run() throws {
        assert(key.count == 32, "Key must be 32 ascii characters")
        print("Hello, world! let's do a thing with file \(inputFile)")
        let plaintext: Data = "Some Super Secret Message".data(using: String.Encoding.utf8)!
        // let keyString = "dm5Eb092Ymk1MEpWZDhvWA=="      // base64 encoded 32-character ASCII
        
        guard let keyData = Data(base64Encoded: key) else {
            fatalError("could not base64-decode key string :(")
        }
        
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
        
        
    }
}

Encrypt.main()
