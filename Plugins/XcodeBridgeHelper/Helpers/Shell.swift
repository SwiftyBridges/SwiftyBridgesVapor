import Foundation

enum Shell {
    /// Runs the given command in Z shell and returns the output
    @discardableResult static func runCommand(_ command: String) throws -> String {
        let outputPipe = Pipe()
        
        let zShellProcess = Process()
        zShellProcess.executableURL = URL(fileURLWithPath: "/bin/zsh")
        zShellProcess.arguments = ["-c", command]
        zShellProcess.standardOutput = outputPipe
        zShellProcess.standardError = outputPipe
        
        try zShellProcess.run()
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
