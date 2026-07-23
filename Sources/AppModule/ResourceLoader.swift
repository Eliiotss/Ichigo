import Foundation
import os

/// Shared decoding helper for the app's bundled JSON datasets.
///
/// Every dataset (kanji, vocabulary, grammar, kana) is a JSON array of `Codable`
/// values loaded through ``JSONResourceCache``. Centralising the decode here keeps
/// the individual loaders free of duplicated error handling and guarantees a
/// consistent, non-throwing contract: on any failure the caller receives an empty
/// array and the reason is written to the unified log so the UI can present a
/// graceful empty state instead of crashing.
enum ResourceLoader {
    static func loadArray<Element: Decodable>(_ type: Element.Type, from filename: String) -> [Element] {
        do {
            return try JSONResourceCache.shared.decode([Element].self, filename: filename)
        } catch {
            Log.resources.error(
                "Failed to load \(filename, privacy: .public).json: \(error.localizedDescription, privacy: .public)"
            )
            return []
        }
    }
}
