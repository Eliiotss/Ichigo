import Foundation

private final class BundleFinder {}

enum JSONResourceCacheError: LocalizedError {
    case missingResource(String)
    case emptyResource(String)
    case decodeFailed(String, String)
    
    var errorDescription: String? {
        switch self {
        case .missingResource(let filename):
            return "File resource \(filename).json tidak ditemukan."
        case .emptyResource(let filename):
            return "File resource \(filename).json kosong."
        case .decodeFailed(let filename, let reason):
            return "Gagal membaca \(filename).json: \(reason)"
        }
    }
}

final class JSONResourceCache {
    static let shared = JSONResourceCache()
    
    private var dataCache: [String: Data] = [:]
    private var decodedCache: [String: Any] = [:]
    private let lock = NSLock()
    private let maxDecodedEntries = 24
    private let maxDataEntries = 24
    
    private init() {}
    
    func decode<T: Decodable>(_ type: T.Type, filename: String) throws -> T {
        let decodedKey = filename + "::" + String(reflecting: type)
        lock.lock()
        if let cached = decodedCache[decodedKey] as? T {
            lock.unlock()
            return cached
        }
        lock.unlock()
        
        let resourceData = try data(for: filename)
        do {
            let decoded = try JSONDecoder().decode(type, from: resourceData)
            lock.lock()
            decodedCache[decodedKey] = decoded
            trimIfNeededLocked()
            lock.unlock()
            return decoded
        } catch {
            throw JSONResourceCacheError.decodeFailed(filename, error.localizedDescription)
        }
    }
    
    func trimAll() {
        lock.lock()
        dataCache.removeAll(keepingCapacity: false)
        decodedCache.removeAll(keepingCapacity: false)
        lock.unlock()
    }
    
    private func data(for filename: String) throws -> Data {
        lock.lock()
        if let cached = dataCache[filename] {
            lock.unlock()
            return cached
        }
        lock.unlock()
        
        guard let url = resolveResourceURL(filename: filename) else {
            throw JSONResourceCacheError.missingResource(filename)
        }
        
        let resourceData = try Data(contentsOf: url)
        guard !resourceData.isEmpty else {
            throw JSONResourceCacheError.emptyResource(filename)
        }
        
        lock.lock()
        dataCache[filename] = resourceData
        trimIfNeededLocked()
        lock.unlock()
        return resourceData
    }
    
    private func trimIfNeededLocked() {
        while decodedCache.count > maxDecodedEntries, let key = decodedCache.keys.first {
            decodedCache.removeValue(forKey: key)
        }
        while dataCache.count > maxDataEntries, let key = dataCache.keys.first {
            dataCache.removeValue(forKey: key)
        }
    }
    
    private func resolveResourceURL(filename: String) -> URL? {
        let file = filename + ".json"
        var candidates: [Bundle] = [.main, Bundle(for: BundleFinder.self)]
        candidates += Bundle.allBundles + Bundle.allFrameworks
        
        for bundle in candidates {
            if let url = bundle.url(forResource: filename, withExtension: "json") { return url }
            if let url = bundle.url(forResource: filename, withExtension: "json", subdirectory: "Resources") { return url }
            
            if let resourceURL = bundle.resourceURL {
                let direct = resourceURL.appendingPathComponent(file)
                if FileManager.default.fileExists(atPath: direct.path) { return direct }
                
                let nested = resourceURL.appendingPathComponent("Resources").appendingPathComponent(file)
                if FileManager.default.fileExists(atPath: nested.path) { return nested }
            }
        }
        
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let fallbackPaths = [
            cwd.appendingPathComponent(file),
            cwd.appendingPathComponent("Resources").appendingPathComponent(file),
            cwd.appendingPathComponent("Sources/AppModule/Resources").appendingPathComponent(file)
        ]
        
        for url in fallbackPaths where FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        
        return nil
    }
}
