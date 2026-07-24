import Foundation
import Security
import CryptoKit

/// Proof Key for Code Exchange (RFC 7636) helpers for the OAuth authorization-code
/// flow used by installed apps. No client secret is required.
enum PKCE {
    /// A high-entropy, URL-safe random string used as the code verifier / state.
    static func randomString(byteCount: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        if SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes) != errSecSuccess {
            for i in bytes.indices { bytes[i] = UInt8.random(in: 0...255) }
        }
        return base64URL(Data(bytes))
    }

    /// S256 challenge derived from the verifier.
    static func challenge(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return base64URL(Data(digest))
    }

    static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
