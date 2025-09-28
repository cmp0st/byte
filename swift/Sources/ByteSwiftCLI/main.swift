import ArgumentParser

struct ByteSwiftCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "byte-swift",
        abstract: "A command-line interface for the Byte Swift client",
        subcommands: [DebugCommand.self]
    )
}

ByteSwiftCLI.main()