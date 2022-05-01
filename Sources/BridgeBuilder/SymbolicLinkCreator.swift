//
//  SymbolicLinkCreator.swift
//  
//
//  Created by Stephen Kockentiedt on 01.05.22.
//

import Foundation

enum SymbolicLinkCreator {
    /// Creates a  symbolic link that uses a relative path to the destination
    /// - Parameters:
    ///   - linkPath: The path the link shall be created at
    ///   - linkDestinationPath: The path the link shall point to. This path will be converted to a relative path.
    ///   - successMessage: This message is written to the output if the link is successfully newly created
    ///   - permissionFailureMessage: This message is written to the output if the link does not already exist and we don't have the permission to create the symbolic link
    static func tryToCreateSymbolicLink(atPath linkPath: String, toDestinationPath linkDestinationPath: String, successMessage: String?, permissionFailureMessage: String?) {
        let linkURL = URL(fileURLWithPath: linkPath)
        let linkDestinationURL = URL(fileURLWithPath: linkDestinationPath, relativeTo: linkURL)
        let relativeLinkDestinationPath = linkDestinationURL.asPath(relativeToFileURL: linkURL)
        let currentLinkDestination = try? FileManager.default.destinationOfSymbolicLink(atPath: linkPath)
        
        guard currentLinkDestination != relativeLinkDestinationPath else {
            // The symbolic link is already present and points to the correct destination
            return
        }
                
        let linkParentDirectory = URL(fileURLWithPath: linkPath).deletingLastPathComponent().path
        do {
            // Remove the symlink if it already exists:
            try? FileManager.default.removeItem(atPath: linkPath)
            // Create the parant directory if it does not exist:
            try FileManager.default.createDirectory(atPath: linkParentDirectory, withIntermediateDirectories: true)
            // Create the symlink:
            try FileManager.default.createSymbolicLink(atPath: linkPath, withDestinationPath: relativeLinkDestinationPath)
            
            if let successMessage = successMessage {
                print(successMessage)
            }
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain, error.code == 513 {
                // We don't have permission to create the symbolic link
                if let failureMessage = permissionFailureMessage {
                    print(failureMessage)
                }
            }
        }
    }
}
