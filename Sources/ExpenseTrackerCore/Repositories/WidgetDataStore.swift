import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Protocol for saving and retrieving the latest widget snapshot.
public protocol WidgetDataStoreProtocol: Sendable {
    func saveSnapshot(_ snapshot: WidgetSnapshot) async throws
    func loadSnapshot() async -> WidgetSnapshot?
    func clearSnapshot() async throws
}

/// Thread-safe local store for sharing widget and shortcut state across app extensions.
/// Gracefully falls back to the local application container if App Groups are not provisioned.
public final class WidgetDataStore: WidgetDataStoreProtocol, @unchecked Sendable {
    public static let defaultAppGroupIdentifier = "group.com.expensetracker.shared"
    public static let fileName = "widget_snapshot.json"
    
    private let appGroupIdentifier: String?
    private let fallbackDirectoryURL: URL?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    public init(
        appGroupIdentifier: String? = defaultAppGroupIdentifier,
        fallbackDirectoryURL: URL? = nil
    ) {
        self.appGroupIdentifier = appGroupIdentifier
        self.fallbackDirectoryURL = fallbackDirectoryURL
        
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc
        
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }
    
    public var storageFileURL: URL? {
        if let groupId = appGroupIdentifier,
           let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) {
            return containerURL.appendingPathComponent(Self.fileName)
        }
        if let fallback = fallbackDirectoryURL {
            try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
            return fallback.appendingPathComponent(Self.fileName)
        }
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        if let appSupport = paths.first {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
            return appSupport.appendingPathComponent(Self.fileName)
        }
        return nil
    }
    
    public func saveSnapshot(_ snapshot: WidgetSnapshot) async throws {
        guard let url = storageFileURL else { return }
        let data = try encoder.encode(snapshot)
        try data.write(to: url, options: .atomic)
        
        #if canImport(WidgetKit)
        #if os(iOS) || os(macOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
        #endif
    }
    
    public func loadSnapshot() async -> WidgetSnapshot? {
        guard let url = storageFileURL, FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(WidgetSnapshot.self, from: data)
        } catch {
            return nil
        }
    }
    
    public func clearSnapshot() async throws {
        guard let url = storageFileURL, FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        try FileManager.default.removeItem(at: url)
        
        #if canImport(WidgetKit)
        #if os(iOS) || os(macOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
        #endif
    }
}
