import Foundation

// bridge: copyToClient
enum CopyToClientEnum: Codable {
    case firstCase
    case secondCase
}

// bridge: copyToClient
/// This type even has a documentation comment!
///
/// A long one!
struct CopyToClientStruct: Codable {
    var storedProperty: Int
    
    var computedProperty: Int {
        storedProperty + 1
    }
}

// Text before annotation
//bridge:copyToClient
// Text after annotation
class CopyToClientClass: Codable {
    var storedProperty: Int
    
    init(storedProperty: Int) {
        self.storedProperty = storedProperty
    }
    
    var computedProperty: Int {
        storedProperty + 1
    }
}

//bridge: copyToClient
extension CopyToClientStruct {
    func methodInExtension() -> Int {
        storedProperty
    }
}
