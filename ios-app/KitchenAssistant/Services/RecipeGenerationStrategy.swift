import Foundation
import SwiftUI

/// 食譜生成策略管理器
class RecipeGenerationStrategy: ObservableObject {
    
    enum Mode: String, CaseIterable, Identifiable {
        case localMLX = "On-Device (MLX)"
        case server = "Cloud Server"
        case customOllama = "Custom Ollama (Advanced)"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .localMLX:
                return "Complete offline. Uses on-device AI model."
            case .server:
                return "Requires internet. Faster on older devices."
            case .customOllama:
                return "For developers: Connect to your own Ollama instance."
            }
        }
        
        var requirements: String {
            switch self {
            case .localMLX:
                return "iPhone 12+ or M1 Mac. ~500MB model download required."
            case .server:
                return "Active internet connection required."
            case .customOllama:
                return "Requires Ollama server running locally or on network."
            }
        }
    }
    
    @Published var currentMode: Mode = .server
    
    private let mlxGenerator: MLXRecipeGenerator?
    private let serverClient: APIClient
    private let ollamaGenerator: LocalLLMRecipeGenerator
    
    init() {
        self.serverClient = APIClient()
        self.ollamaGenerator = LocalLLMRecipeGenerator()
        
        // 只在支援的裝置上初始化 MLX
        #if targetEnvironment(simulator)
        self.mlxGenerator = nil
        #else
        if #available(iOS 16.0, *), ProcessInfo.processInfo.processorCount >= 6 {
            self.mlxGenerator = MLXRecipeGenerator()
        } else {
            self.mlxGenerator = nil
        }
        #endif
    }
    
    func generateRecipe(
        ingredients: [String],
        mealCraving: String,
        dietaryRestrictions: [String] = [],
        preferredCuisine: String = "Any"
    ) async throws -> Recipe {
        
        switch currentMode {
        case .localMLX:
            guard let mlxGenerator else {
                throw RecipeGenerationError.mlxNotAvailable
            }
            print("🤖 Using on-device MLX LLM")
            return try await mlxGenerator.generateRecipe(
                ingredients: ingredients,
                mealCraving: mealCraving
            )
            
        case .server:
            print("🌐 Using cloud server")
            return try await serverClient.generateRecipe(
                ingredients: ingredients,
                mealCraving: mealCraving
            )
            
        case .customOllama:
            print("🔧 Using custom Ollama instance")
            return try await ollamaGenerator.generateRecipe(
                ingredients: ingredients,
                mealCraving: mealCraving,
                dietaryRestrictions: dietaryRestrictions,
                preferredCuisine: preferredCuisine
            )
        }
    }
    
    func isAvailable(mode: Mode) -> Bool {
        switch mode {
        case .localMLX:
            return mlxGenerator != nil
        case .server:
            return true  // 假設總是可用（實際可加網路檢測）
        case .customOllama:
            return true  // 讓用戶自己決定
        }
    }
}

enum RecipeGenerationError: LocalizedError {
    case mlxNotAvailable
    case ollamaNotReachable
    case serverUnavailable
    
    var errorDescription: String? {
        switch self {
        case .mlxNotAvailable:
            return "On-device AI is not available on this device. Please use Cloud Server mode or upgrade to iPhone 12+."
        case .ollamaNotReachable:
            return "Cannot connect to Ollama server. Make sure it's running and accessible."
        case .serverUnavailable:
            return "Cloud server is currently unavailable. Please try again later or use on-device mode."
        }
    }
}

