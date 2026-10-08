import Foundation

/// Authorization state for microphone and speech recognition services.
public enum SpeechAuthStatus: String, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

/// Service protocol for voice capture and speech-to-text conversion.
/// Invariants per docs/00_PRODUCT_BRAIN.md and docs/04_TECHNICAL_ARCHITECTURE.md:
/// - Contextual permission explanation before requesting system authorization.
/// - Never retain raw audio or transcripts by default.
/// - Supports on-device recognition check.
public protocol SpeechRecognitionServiceProtocol: Sendable {
    var supportsOnDeviceRecognition: Bool { get }
    func checkAuthorizationStatus() async -> SpeechAuthStatus
    func requestAuthorization() async -> SpeechAuthStatus
    func startRecording() async throws -> AsyncStream<String>
    func stopRecording()
    func cancelRecording()
}

/// Lightweight mock service for previews and automated tests.
public final class MockSpeechRecognitionService: SpeechRecognitionServiceProtocol {
    public let supportsOnDeviceRecognition: Bool
    public var mockTranscript: String
    
    public init(supportsOnDeviceRecognition: Bool = true, mockTranscript: String = "Spent 350 rupees on lunch") {
        self.supportsOnDeviceRecognition = supportsOnDeviceRecognition
        self.mockTranscript = mockTranscript
    }
    
    public func checkAuthorizationStatus() async -> SpeechAuthStatus {
        return .authorized
    }
    
    public func requestAuthorization() async -> SpeechAuthStatus {
        return .authorized
    }
    
    public func startRecording() async throws -> AsyncStream<String> {
        let text = mockTranscript
        return AsyncStream { continuation in
            continuation.yield(text)
            continuation.finish()
        }
    }
    
    public func stopRecording() {}
    public func cancelRecording() {}
}
