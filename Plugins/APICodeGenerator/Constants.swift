import Foundation

/// Contains certain constants used across the package. Due to Swift Package Manager not allowing to reuse a file in multiple target, this enum is duplicated in the different targets.
///
/// WARNING: If you update or add a value, please also do so in the other targets.
public enum Constants {
    public static let apiCodeGeneratorPluginName = "APICodeGenerator"
    
    public static let generatedClientCodeSubfolderName = "GeneratedClientCode"
    
    public static func packageFolderClientCodeSubfolder(forTargetName targetName: String) -> String {
        "GeneratedClientCode/\(targetName)"
    }
}
