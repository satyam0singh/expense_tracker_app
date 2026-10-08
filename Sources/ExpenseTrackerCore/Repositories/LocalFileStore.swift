import Foundation

/// Safe, atomic local JSON storage engine for local-first persistence.
/// Invariant: Works 100% offline without networking, third-party packages, or cloud synchronization.
public actor LocalFileStore {
    public let baseDirectory: URL
    private let fileManager = FileManager.default
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    
    public init(baseDirectory: URL? = nil) {
        if let dir = baseDirectory {
            self.baseDirectory = dir
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.baseDirectory = appSupport.appendingPathComponent("ExpenseTracker", isDirectory: true)
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.jsonEncoder = encoder
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.jsonDecoder = decoder
        
        createDirectoryIfNeeded()
    }
    
    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: baseDirectory.path) {
            try? fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    // MARK: - Generic Persistence Helpers
    
    public func load<T: Decodable>(_ type: T.Type, filename: String) throws -> T? {
        let fileURL = baseDirectory.appendingPathComponent(filename)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: fileURL)
        return try jsonDecoder.decode(T.self, from: data)
    }
    
    public func save<T: Encodable>(_ object: T, filename: String) throws {
        createDirectoryIfNeeded()
        let fileURL = baseDirectory.appendingPathComponent(filename)
        let data = try jsonEncoder.encode(object)
        try data.write(to: fileURL, options: [.atomic])
    }
    
    public func delete(filename: String) throws {
        let fileURL = baseDirectory.appendingPathComponent(filename)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    public func clearAllData() throws {
        if fileManager.fileExists(atPath: baseDirectory.path) {
            let contents = try fileManager.contentsOfDirectory(at: baseDirectory, includingPropertiesForKeys: nil)
            for file in contents {
                try fileManager.removeItem(at: file)
            }
        }
    }
}
