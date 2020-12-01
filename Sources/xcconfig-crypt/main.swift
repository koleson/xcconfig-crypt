import Foundation
import ArgumentParser
import Crypto

struct XCConfigCrypt: ParsableCommand {
    static var configuration = CommandConfiguration(subcommands: [Encrypt.self, Decrypt.self])
}

XCConfigCrypt.main()
