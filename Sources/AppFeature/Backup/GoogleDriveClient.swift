import Foundation

/// Minimal Google Drive REST client scoped to the hidden per-app `appDataFolder`.
/// Given a valid access token it can find, create, update and download the single
/// backup file. No third-party dependency — plain `URLSession`.
struct GoogleDriveClient {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    struct FileRef {
        let id: String
        let modifiedTime: Date?
    }

    func findBackup(named name: String, accessToken: String) async throws -> FileRef? {
        var components = URLComponents(string: "https://www.googleapis.com/drive/v3/files")
        components?.queryItems = [
            URLQueryItem(name: "spaces", value: "appDataFolder"),
            URLQueryItem(name: "q", value: "name = '\(name)' and trashed = false"),
            URLQueryItem(name: "fields", value: "files(id,name,modifiedTime)"),
            URLQueryItem(name: "pageSize", value: "1")
        ]
        guard let url = components?.url else { throw DriveBackupError.network("URL tidak valid.") }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await perform(request)
        try ensureSuccess(response, data)
        let list = try JSONDecoder().decode(FileList.self, from: data)
        guard let file = list.files.first else { return nil }
        let modified = file.modifiedTime.flatMap { ISO8601DateFormatter().date(from: $0) }
        return FileRef(id: file.id, modifiedTime: modified)
    }

    @discardableResult
    func create(named name: String, content: Data, accessToken: String) async throws -> String {
        let boundary = "ichigo-\(UUID().uuidString)"
        let metadata: [String: Any] = ["name": name, "parents": ["appDataFolder"]]
        let metadataData = try JSONSerialization.data(withJSONObject: metadata)

        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Type: application/json; charset=UTF-8\r\n\r\n")
        body.append(metadataData)
        body.appendString("\r\n--\(boundary)\r\n")
        body.appendString("Content-Type: application/json\r\n\r\n")
        body.append(content)
        body.appendString("\r\n--\(boundary)--\r\n")

        guard let url = URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart") else {
            throw DriveBackupError.network("URL tidak valid.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response) = try await perform(request)
        try ensureSuccess(response, data)
        return try JSONDecoder().decode(FileIDResponse.self, from: data).id
    }

    func update(fileID: String, content: Data, accessToken: String) async throws {
        guard let url = URL(string: "https://www.googleapis.com/upload/drive/v3/files/\(fileID)?uploadType=media") else {
            throw DriveBackupError.network("URL tidak valid.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = content

        let (data, response) = try await perform(request)
        try ensureSuccess(response, data)
    }

    func download(fileID: String, accessToken: String) async throws -> Data {
        guard let url = URL(string: "https://www.googleapis.com/drive/v3/files/\(fileID)?alt=media") else {
            throw DriveBackupError.network("URL tidak valid.")
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await perform(request)
        try ensureSuccess(response, data)
        return data
    }

    // MARK: - Helpers

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw DriveBackupError.network(error.localizedDescription)
        }
    }

    private func ensureSuccess(_ response: URLResponse, _ data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw DriveBackupError.network("Respons tidak valid.")
        }
        guard (200..<300).contains(http.statusCode) else {
            let detail = String(data: data, encoding: .utf8).map { String($0.prefix(200)) } ?? ""
            throw DriveBackupError.network("HTTP \(http.statusCode) \(detail)")
        }
    }

    private struct FileList: Decodable { let files: [DriveFile] }
    private struct DriveFile: Decodable { let id: String; let name: String?; let modifiedTime: String? }
    private struct FileIDResponse: Decodable { let id: String }
}

private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) { append(data) }
    }
}
