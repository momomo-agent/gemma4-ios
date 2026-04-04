import CoreImage
import Foundation
import MLX
import MLXVLM
import MLXLMCommon

enum ModelChoice: String, CaseIterable, Identifiable {
    case gemma4_e2b = "Gemma 4 E2B"
    case gemma4_e4b = "Gemma 4 E4B"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .gemma4_e2b: "2.3B effective · ~3GB · text + image"
        case .gemma4_e4b: "4.5B effective · ~5GB · text + image"
        }
    }

    var sizeHint: String {
        switch self {
        case .gemma4_e2b: "~3GB"
        case .gemma4_e4b: "~5GB"
        }
    }

    var configuration: ModelConfiguration {
        switch self {
        case .gemma4_e2b: VLMRegistry.gemma4_E2B_it_4bit
        case .gemma4_e4b: VLMRegistry.gemma4_E4B_it_4bit
        }
    }
}

@Observable
class GemmaModel {
    var isLoaded = false
    var error: String?
    var loadProgress: Double = 0
    var currentModel: ModelChoice = .gemma4_e2b

    private var container: ModelContainer?
    private var chatSession: ChatSession?

    func load(choice: ModelChoice) async {
        isLoaded = false
        error = nil
        loadProgress = 0
        currentModel = choice
        container = nil
        chatSession = nil

        do {
            let config = choice.configuration
            let loaded = try await loadModelContainer(configuration: config) { progress in
                Task { @MainActor in
                    self.loadProgress = progress.fractionCompleted * 0.95
                }
            }
            container = loaded
            chatSession = ChatSession(
                loaded,
                instructions: "You are a helpful AI assistant. Respond concisely.",
                generateParameters: GenerateParameters(temperature: 0.7, topP: 0.9)
            )
            loadProgress = 1.0
            isLoaded = true
        } catch {
            self.error = "加载失败: \(error.localizedDescription)"
        }
    }

    func generate(prompt: String, image: CGImage? = nil, onToken: @escaping @MainActor (String) -> Void) async {
        guard let chatSession else {
            await onToken("Model not loaded")
            return
        }

        do {
            let images: [UserInput.Image] = if let image {
                [.ciImage(CIImage(cgImage: image))]
            } else {
                []
            }

            let effectivePrompt = prompt.isEmpty ? "Describe this image in detail." : prompt

            let stream = chatSession.streamResponse(
                to: effectivePrompt,
                images: images,
                videos: []
            )
            for try await chunk in stream {
                await onToken(chunk)
            }
        } catch {
            await onToken("\nError: \(error.localizedDescription)")
        }
    }
}
