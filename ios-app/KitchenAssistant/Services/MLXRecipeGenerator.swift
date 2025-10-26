import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import Hub

/// 使用 MLX 在裝置上生成食譜（完全離線）
@available(iOS 16.0, macOS 14.0, *)
class MLXRecipeGenerator {
    
    // MARK: - Properties
    
    private var modelContainer: ModelContainer?
    private let modelConfiguration: ModelConfiguration
    
    private var isModelLoaded = false
    private var isLoading = false
    private var loadError: Error?
    
    // MARK: - Initialization
    
    init() {
        // 使用 Qwen2.5-0.5B-Instruct-4bit 模型
        self.modelConfiguration = ModelConfiguration(
            id: "mlx-community/Qwen2.5-0.5B-Instruct-4bit"
        )
        
        print("✅ MLXRecipeGenerator 初始化")
        
        // 異步載入模型
        Task {
            await loadModel()
        }
    }
    
    // MARK: - Public Methods
    
    /// 檢查模型是否已載入
    var modelStatus: ModelStatus {
        if isLoading {
            return .loading
        } else if isModelLoaded {
            return .ready
        } else if let error = loadError {
            return .failed(error)
        } else {
            return .notLoaded
        }
    }
    
    /// 生成食譜
    func generateRecipe(ingredients: [String], mealCraving: String? = nil) async throws -> Recipe {
        print("🤖 開始使用 MLX 生成食譜...")
        print("📝 食材: \(ingredients.joined(separator: ", "))")
        if let craving = mealCraving, !craving.isEmpty {
            print("🍽️ 想吃: \(craving)")
        }
        
        // 確保模型已載入，如果沒有則等待載入
        if !isModelLoaded {
            print("⏳ 模型尚未載入，開始載入...")
            await loadModel()
            
            // 等待載入完成
            var attempts = 0
            print("⏱️ 等待模型載入完成... isModelLoaded=\(isModelLoaded), isLoading=\(isLoading)")
            while isLoading && attempts < 300 {  // 最多等待 5 分鐘
                try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 秒
                attempts += 1
                if attempts % 5 == 0 {
                    print("⏱️ 等待中... attempts=\(attempts), isModelLoaded=\(isModelLoaded), isLoading=\(isLoading)")
                }
            }
            
            print("⏱️ 等待結束: attempts=\(attempts), isModelLoaded=\(isModelLoaded), isLoading=\(isLoading)")
            
            // 檢查是否成功載入
            guard isModelLoaded, let container = modelContainer else {
                if let error = loadError {
                    print("❌ 模型載入失敗: \(error)")
                    throw error
                }
                throw MLXError.modelNotLoaded
            }
            
            print("✅ 模型載入完成，開始生成...")
        }
        
        guard let container = modelContainer else {
            throw MLXError.modelNotLoaded
        }
        
        // 建立提示詞
        let prompt = buildPrompt(ingredients: ingredients, mealCraving: mealCraving)
        print("📤 提示詞長度: \(prompt.count) 字元")
        
        // 生成回應
        let startTime = Date()
        let session = ChatSession(container)
        let response = try await session.respond(to: prompt)
        let duration = Date().timeIntervalSince(startTime)
        
        print("✅ MLX 生成完成，耗時: \(String(format: "%.1f", duration)) 秒")
        print("📥 回應長度: \(response.count) 字元")
        
        // 解析 JSON 回應
        return try parseRecipe(from: response, duration: duration)
    }
    
    // MARK: - Private Methods
    
    /// 載入模型
    private func loadModel() async {
        guard !isLoading && !isModelLoaded else { return }
        
        isLoading = true
        loadError = nil
        
        print("📦 開始載入 MLX 模型...")
        
        do {
            // 使用 HubApi 和 LLMModelFactory 載入模型
            let hub = HubApi()
            
            let modelContext = try await LLMModelFactory.shared.load(
                hub: hub,
                configuration: modelConfiguration
            ) { progress in
                print("📊 模型載入進度: \(Int(progress.fractionCompleted * 100))%")
            }
            
            // ModelContext 包含 model, tokenizer, processor 等
            self.modelContainer = ModelContainer(context: modelContext)
            self.isModelLoaded = true
            print("✅ MLX 模型載入成功")
            
        } catch {
            print("❌ MLX 模型載入失敗: \(error)")
            self.loadError = error
        }
        
        isLoading = false
    }
    
    /// 建立提示詞
    private func buildPrompt(ingredients: [String], mealCraving: String?) -> String {
        var prompt = """
        You are a professional chef assistant. Generate a recipe using the following ingredients.
        Return ONLY a valid JSON object with this exact structure (no markdown, no explanations):
        
        {
          "title": "Recipe Name",
          "ingredients": ["ingredient 1 with amount", "ingredient 2 with amount"],
          "steps": ["step 1", "step 2", "step 3"],
          "prepTime": "15 minutes",
          "cookTime": "30 minutes",
          "servings": 2
        }
        
        Available ingredients: \(ingredients.joined(separator: ", "))
        """
        
        if let craving = mealCraving, !craving.isEmpty {
            prompt += "\nDish preference: \(craving)"
        }
        
        prompt += "\n\nGenerate the recipe JSON:"
        
        return prompt
    }
    
    /// 解析食譜
    private func parseRecipe(from response: String, duration: TimeInterval) throws -> Recipe {
        print("🔍 開始解析 JSON 回應...")
        
        // 清理回應文字
        var cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 移除 markdown 代碼塊標記
        if cleanedResponse.hasPrefix("```json") {
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```json", with: "")
        }
        if cleanedResponse.hasPrefix("```") {
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```", with: "")
        }
        if cleanedResponse.hasSuffix("```") {
            cleanedResponse = String(cleanedResponse.dropLast(3))
        }
        cleanedResponse = cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 嘗試找到 JSON 對象
        if let startIndex = cleanedResponse.firstIndex(of: "{"),
           let endIndex = cleanedResponse.lastIndex(of: "}") {
            cleanedResponse = String(cleanedResponse[startIndex...endIndex])
        }
        
        // 解析 JSON
        guard let jsonData = cleanedResponse.data(using: .utf8) else {
            print("❌ 無法將回應轉換為 Data")
            throw MLXError.invalidResponse("無法將回應轉換為 Data")
        }
        
        do {
            let recipeResponse = try JSONDecoder().decode(RecipeResponse.self, from: jsonData)
            print("✅ JSON 解析成功")
            
            // 將 String 轉換為 Ingredient
            let ingredients = recipeResponse.ingredients.map { ingredientStr in
                Ingredient(name: ingredientStr, amount: "適量", unit: nil, notes: nil)
            }
            
            // 將 String 轉換為 Instruction
            let instructions = recipeResponse.steps.enumerated().map { (index, step) in
                Instruction(step: index + 1, text: step, time: nil, temperature: nil, tips: nil)
            }
            
            // 將時間字符串轉換為整數（提取數字）
            let prepTimeInt = Int(recipeResponse.prepTime.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 15
            let cookTimeInt = Int(recipeResponse.cookTime.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 30
            
            return Recipe(
                title: recipeResponse.title,
                description: "由 MLX on-device LLM 生成 (耗時 \(String(format: "%.1f", duration))秒)",
                prepTime: prepTimeInt,
                cookTime: cookTimeInt,
                servings: recipeResponse.servings,
                difficulty: .easy,
                ingredients: ingredients,
                instructions: instructions,
                tags: ["MLX Generated"],
                nutritionInfo: nil
            )
        } catch {
            print("❌ JSON 解析失敗: \(error)")
            print("📄 原始回應: \(response)")
            print("🧹 清理後: \(cleanedResponse)")
            
            // 如果解析失敗，返回備用食譜
            return fallbackRecipe(error: error)
        }
    }
    
    /// 備用食譜（當解析失敗時）
    private func fallbackRecipe(error: Error) -> Recipe {
        return Recipe(
            title: "簡易炒菜",
            description: "MLX 生成失敗，這是備用食譜。錯誤: \(error.localizedDescription)",
            prepTime: 5,
            cookTime: 10,
            servings: 2,
            difficulty: .easy,
            ingredients: [
                Ingredient(name: "蔬菜", amount: "適量", unit: nil, notes: nil),
                Ingredient(name: "食用油", amount: "2", unit: "湯匙", notes: nil),
                Ingredient(name: "鹽", amount: "適量", unit: nil, notes: nil),
                Ingredient(name: "蒜", amount: "2", unit: "瓣", notes: nil)
            ],
            instructions: [
                Instruction(step: 1, text: "將蔬菜洗淨切好", time: 2, temperature: nil, tips: nil),
                Instruction(step: 2, text: "熱鍋加油，爆香蒜末", time: 2, temperature: nil, tips: nil),
                Instruction(step: 3, text: "加入蔬菜快速翻炒", time: 5, temperature: nil, tips: nil),
                Instruction(step: 4, text: "加鹽調味即可", time: 1, temperature: nil, tips: nil)
            ],
            tags: ["Simple", "Fallback"],
            nutritionInfo: nil
        )
    }
}

// MARK: - Supporting Types

@available(iOS 16.0, macOS 14.0, *)
enum ModelStatus {
    case notLoaded
    case loading
    case ready
    case failed(Error)
    
    var description: String {
        switch self {
        case .notLoaded: return "未載入"
        case .loading: return "載入中..."
        case .ready: return "就緒"
        case .failed(let error): return "失敗: \(error.localizedDescription)"
        }
    }
}

@available(iOS 16.0, macOS 14.0, *)
enum MLXError: LocalizedError {
    case modelNotLoaded
    case invalidResponse(String)
    case generationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "MLX 模型尚未載入"
        case .invalidResponse(let details):
            return "無效的回應: \(details)"
        case .generationFailed(let details):
            return "生成失敗: \(details)"
        }
    }
}

// MARK: - JSON Response Model

private struct RecipeResponse: Codable {
    let title: String
    let ingredients: [String]
    let steps: [String]
    let prepTime: String
    let cookTime: String
    let servings: Int
    
    enum CodingKeys: String, CodingKey {
        case title
        case ingredients
        case steps
        case prepTime = "prepTime"
        case cookTime = "cookTime"
        case servings
    }
}
