import Foundation

/// OAuth configuration for the Google Drive backup feature.
///
/// The iOS OAuth *client ID* is not a secret — it ships inside every installed
/// build and is protected by PKCE — but it is project-specific, so it is read at
/// runtime from a `GoogleOAuth.plist` resource containing a `CLIENT_ID` string.
/// When the file is missing (or still holds the placeholder), the feature reports
/// itself as not configured and the UI shows setup instructions instead.
struct GoogleDriveConfig: Equatable {
    let clientID: String

    /// Reversed-client-id URL scheme Google expects for installed-app redirects,
    /// e.g. `123-abc.apps.googleusercontent.com` → `com.googleusercontent.apps.123-abc`.
    var redirectScheme: String {
        let suffix = ".apps.googleusercontent.com"
        let base = clientID.hasSuffix(suffix) ? String(clientID.dropLast(suffix.count)) : clientID
        return "com.googleusercontent.apps.\(base)"
    }

    var redirectURI: String { "\(redirectScheme):/oauth2redirect" }

    /// Restricted to the hidden per-app data folder — the app can only see its own
    /// backups, never the user's other Drive files.
    static let scope = "https://www.googleapis.com/auth/drive.appdata"

    /// Loads the config from `GoogleOAuth.plist`. Searches the main bundle and this
    /// module's framework bundle (not `Bundle.module`, which is unavailable in the
    /// Swift Playgrounds build system). Pass an explicit `bundle` in tests.
    static func load(bundle: Bundle? = nil) -> GoogleDriveConfig? {
        let searchBundles = bundle.map { [$0] } ?? [.main, Bundle(for: BundleToken.self)]
        for candidate in searchBundles {
            guard let url = candidate.url(forResource: "GoogleOAuth", withExtension: "plist"),
                  let dict = NSDictionary(contentsOf: url),
                  let clientID = dict["CLIENT_ID"] as? String,
                  !clientID.isEmpty,
                  !clientID.hasPrefix("YOUR_") else {
                continue
            }
            return GoogleDriveConfig(clientID: clientID)
        }
        return nil
    }
}

private final class BundleToken {}
