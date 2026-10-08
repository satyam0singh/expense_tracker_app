import SwiftUI
import ExpenseTrackerCore

public struct VoiceCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    private let speechService: SpeechRecognitionServiceProtocol
    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let currencyCode: String
    private let onSaved: (Transaction) -> Void
    
    enum CaptureState {
        case explainer
        case listening
        case review(VoiceParseResult)
        case deniedOrUnavailable(String)
    }
    
    @State private var state: CaptureState = .explainer
    @State private var liveTranscript: String = ""
    @State private var categories: [Category] = []
    
    public init(
        speechService: SpeechRecognitionServiceProtocol = MockSpeechRecognitionService(),
        transactionRepository: TransactionRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol,
        currencyCode: String = "INR",
        onSaved: @escaping (Transaction) -> Void = { _ in }
    ) {
        self.speechService = speechService
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.currencyCode = currencyCode
        self.onSaved = onSaved
    }
    
    public var body: some View {
        Group {
            switch state {
            case .explainer:
                explainerView
            case .listening:
                listeningView
            case .review(let result):
                VoiceReviewView(
                    transactionRepository: transactionRepository,
                    categoryRepository: categoryRepository,
                    parseResult: result,
                    currencyCode: currencyCode,
                    onSaved: { tx in
                        onSaved(tx)
                        dismiss()
                    }
                )
            case .deniedOrUnavailable(let message):
                deniedView(message: message)
            }
        }
        .task {
            categories = (try? await categoryRepository.list(includeArchived: false)) ?? []
        }
    }
    
    // MARK: - Subviews
    
    private var explainerView: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
                
                VStack(spacing: 8) {
                    Text("Speak an Expense")
                        .font(.title2.weight(.bold))
                    
                    Text("Say something natural like:\n\"Spent 350 rupees on lunch\"\nor \"₹250 chai, UPI\".")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(.green)
                        Text("Private & On-Device")
                            .font(.subheadline.weight(.semibold))
                    }
                    Text("Audio is converted to text on your device. Antigravity never stores raw audio recordings or sends your transcripts to cloud servers.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: startListening) {
                        Text("Start Listening")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var listeningView: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Pulsing Mic Indicator
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                }
                
                VStack(spacing: 12) {
                    Text("Listening...")
                        .font(.title2.weight(.bold))
                    
                    Text(liveTranscript.isEmpty ? "Speak now (e.g. 'Coffee 150')" : "\"\(liveTranscript)\"")
                        .font(.headline)
                        .foregroundStyle(liveTranscript.isEmpty ? .secondary : .primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        speechService.cancelRecording()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Done") {
                        finishListening()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom, 24)
            }
        }
    }
    
    private func deniedView(message: String) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "mic.slash.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)
                
                Text("Microphone Unavailable")
                    .font(.title2.weight(.bold))
                
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Actions
    
    private func startListening() {
        Task {
            let auth = await speechService.requestAuthorization()
            guard auth == .authorized else {
                await MainActor.run {
                    self.state = .deniedOrUnavailable("Microphone access was denied. You can enable it in iOS Settings or record expenses manually.")
                }
                return
            }
            
            await MainActor.run {
                self.state = .listening
            }
            
            do {
                let stream = try await speechService.startRecording()
                for await text in stream {
                    await MainActor.run {
                        self.liveTranscript = text
                    }
                }
                // When stream finishes automatically
                await MainActor.run {
                    finishListening()
                }
            } catch {
                await MainActor.run {
                    self.state = .deniedOrUnavailable(error.localizedDescription)
                }
            }
        }
    }
    
    private func finishListening() {
        speechService.stopRecording()
        let result = VoiceTransactionParser.parse(
            transcript: liveTranscript,
            defaultCurrencyCode: currencyCode,
            categories: categories
        )
        self.state = .review(result)
    }
}
