import Vapor

extension Validatable where Self: Encodable {
    /// Validates this instance using the validations defined in `validations()`. Throws if there was an error encoding or decoding the instance or if there was a validation error.
    public func validate() throws {
        let jsonData = try JSONEncoder().encode(self)
        let decoder = try JSONDecoder().decode(DecoderUnwrapper.self, from: jsonData)
        try Self.validate(decoder.decoder)
    }
}
