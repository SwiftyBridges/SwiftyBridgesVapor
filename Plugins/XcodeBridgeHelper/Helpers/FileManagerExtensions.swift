import Foundation

extension FileManager {
    /// Returns true if there exists a directory at the given file URL
    func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = self.fileExists(atPath: url.path, isDirectory:&isDirectory)
        return exists && isDirectory.boolValue
    }
    
    /// First, creates the parent directory of the destination URL if it doesn't exist. Then, it removes the item at the destination URL if it exists. Finally, copies the item at the source URL to the destination URL.
    /// - Parameters:
    ///   - sourceURL: The URL of the item to be copied. MUST be a file URL.
    ///   - destinationURL: The URL the source item shall be copied to. MUST be a file URL.
    func robustlyCopyItem(at sourceURL: URL, to destinationURL: URL) throws {
        try? createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? removeItem(at: destinationURL)
        try copyItem(at: sourceURL, to: destinationURL)
    }
}
