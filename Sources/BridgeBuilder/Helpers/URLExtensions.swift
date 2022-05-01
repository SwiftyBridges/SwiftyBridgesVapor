//
//  URLExtensions.swift
//  
//
//  Created by Stephen Kockentiedt on 01.05.22.
//

import Foundation

extension URL {
    /// Returns the relative path of this URL as seen from the given file URL. It is assumed that the given URL points to a file.
    func asPath(relativeToFileURL fileURL: URL) -> String {
        let components = self.standardized.pathComponents
        let fileURLComponents = fileURL.standardized.pathComponents.dropLast()
        
        let commonComponentCount = zip(components, fileURLComponents)
            .prefix(while: { $0.0 == $0.1 })
            .count
        
        return (Array(repeating: "..", count: fileURLComponents.count - commonComponentCount) + components[commonComponentCount...])
            .joined(separator: "/")
    }
}
