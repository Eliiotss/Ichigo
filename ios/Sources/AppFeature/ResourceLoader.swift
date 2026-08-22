import Foundation
import os

/// Shared decoding helper for the app's bundled JSON datasets.
///
/// Every dataset (kanji, vocabulary, grammar, kana) is a JSON array of `Codable`
/// values loaded through ``JSONResourceCache``. Centralising the decode here keeps
/// the individual loaders free of duplicated error handling, and every failure is
/// written to the unified log exactly once, here.
///
/// Two contracts are offered because callers genuinely differ. A browsing screen
/// must be able to tell "this level has no data yet" apart from "this file is
/// missing or corrupt" — it shows a different state for each — so it uses the
/// throwing ``loadArray(_:from:)``. A caller that has a usable fallback, such as
/// a flashcard deck that simply has nothing to review, uses
/// ``loadArrayOrEmpty(_:from:)`` instead of writing its own `try?`.
enum ResourceLoader {
    /// Decodes a bundled dataset, propagating the reason on failure.
    static func loadArray<Element: Decodable>(_ type: Element.Type, from filename: String) throws -> [Element] {
        do {
            return try JSONResourceCache.shared.decode([Element].self, filename: filename)
        } catch {
            Log.resources.error(
                "Failed to load \(filename, privacy: .public).json: \(error.localizedDescription, privacy: .public)"
            )
            throw error
        }
    }

    /// Decodes a bundled dataset, yielding an empty array when it cannot be read.
    /// The failure is still logged by ``loadArray(_:from:)``.
    static func loadArrayOrEmpty<Element: Decodable>(_ type: Element.Type, from filename: String) -> [Element] {
        (try? loadArray(type, from: filename)) ?? []
    }
}
