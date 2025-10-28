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
        // 使用 0.5B 模型（已在 iPhone 16 Pro 上测试，运行稳定）
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
        
        // 生成回應（已簡化 prompt 以減少內存使用）
        let startTime = Date()
        print("🎯 開始 MLX 推理（這可能需要 30-60 秒）...")
        print("💾 提示：MLX 需要較多內存，如遇問題請關閉其他 App")

        let session = ChatSession(container)

        // 使用 withTimeout 來避免無限等待
        let response: String
        do {
            response = try await withTimeout(seconds: 120) {
                let result = try await session.respond(to: prompt)
                print("📤 MLX 推理完成，開始處理回應...")
                return result
            }
        } catch {
            print("❌ MLX 推理超時或失敗: \(error)")
            throw MLXError.generationFailed("推理超時: \(error.localizedDescription)")
        }

        let duration = Date().timeIntervalSince(startTime)

        print("✅ MLX 生成完成，耗時: \(String(format: "%.1f", duration)) 秒")
        print("📥 回應長度: \(response.count) 字元")
        print("📄 完整回應內容:")
        print("─────────────────────────────────────")
        print(response)
        print("─────────────────────────────────────")

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
    
    /// 建立提示詞（改進版：更多指導，但不過長）
    private func buildPrompt(ingredients: [String], mealCraving: String?) -> String {
        let ingredientsList = ingredients.joined(separator: ", ")
        let dishType = mealCraving ?? "dish"

        return """
Create a \(dishType) recipe using ONLY these ingredients: \(ingredientsList)

IMPORTANT RULES:
1. Use ONLY these ingredients + basic items (salt, pepper, oil, water if needed)
2. NO extra ingredients
3. Write 5-7 unique steps, NO repetition
4. Tags must match dish type (\(dishType))
5. Steps must be DIFFERENT from each other

EXAMPLE OUTPUT (for pasta):
{
  "title": "Simple Pasta",
  "description": "Quick pasta dish",
  "prepTime": 5,
  "cookTime": 15,
  "servings": 2,
  "difficulty": "Easy",
  "ingredients": [
    {"name": "Cheese", "amount": "1", "unit": "cup", "notes": null},
    {"name": "Salt", "amount": "1", "unit": "tsp", "notes": null}
  ],
  "instructions": [
    {"step": 1, "text": "Boil water in a pot", "time": 5, "temperature": null, "tips": null},
    {"step": 2, "text": "Add pasta and cook 10 minutes", "time": 10, "temperature": null, "tips": null},
    {"step": 3, "text": "Drain pasta", "time": 1, "temperature": null, "tips": null},
    {"step": 4, "text": "Mix with cheese and salt", "time": 2, "temperature": null, "tips": null},
    {"step": 5, "text": "Serve hot", "time": 0, "temperature": null, "tips": null}
  ],
  "tags": ["pasta", "main"],
  "nutritionInfo": null
}

NOW CREATE YOUR RECIPE for \(dishType):
"""
    }
    
    /// 解析食譜
    private func parseRecipe(from response: String, duration: TimeInterval) throws -> Recipe {
        print("🔍 開始解析 JSON 回應...")
        print("📏 原始回應長度: \(response.count) 字元")
        print("📄 完整原始回應:")
        print("─────────────────────────────────────")
        print(response)
        print("─────────────────────────────────────")

        // 清理回應文字
        var cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)

        // 移除 markdown 代碼塊標記（所有可能的變體）
        let markdownPrefixes = ["```json", "```JSON", "```"]
        for prefix in markdownPrefixes {
            if cleanedResponse.hasPrefix(prefix) {
                cleanedResponse = String(cleanedResponse.dropFirst(prefix.count))
            }
        }

        // 移除結尾的 ```
        while cleanedResponse.hasSuffix("```") {
            cleanedResponse = String(cleanedResponse.dropLast(3))
        }

        cleanedResponse = cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines)

        // 嘗試找到 JSON 對象（找第一個 { 和最後一個 }）
        if let startIndex = cleanedResponse.firstIndex(of: "{"),
           let endIndex = cleanedResponse.lastIndex(of: "}") {
            let range = startIndex...endIndex
            cleanedResponse = String(cleanedResponse[range])
        } else {
            print("❌ 找不到 JSON 對象的開始或結束標記")
            print("📄 清理後內容: \(cleanedResponse.prefix(200))...")
            throw MLXError.invalidResponse("找不到有效的 JSON 對象")
        }

        print("📏 清理後 JSON 長度: \(cleanedResponse.count) 字元")
        print("📄 JSON 開頭: \(cleanedResponse.prefix(100))...")
        print("📄 JSON 結尾: ...\(cleanedResponse.suffix(100))")

        // 解析 JSON
        guard let jsonData = cleanedResponse.data(using: .utf8) else {
            print("❌ 無法將回應轉換為 Data")
            throw MLXError.invalidResponse("無法將回應轉換為 Data")
        }
        
        do {
            let recipeResponse = try JSONDecoder().decode(RecipeResponse.self, from: jsonData)
            print("✅ JSON 解析成功")

            // 轉換 difficulty
            let recipeDifficulty: Recipe.Difficulty
            switch recipeResponse.difficulty.lowercased() {
            case "easy": recipeDifficulty = .easy
            case "medium": recipeDifficulty = .medium
            case "hard": recipeDifficulty = .hard
            default: recipeDifficulty = .easy
            }

            // 轉換 ingredients
            let ingredients = recipeResponse.ingredients.map { mlxIng in
                Ingredient(
                    name: mlxIng.name,
                    amount: mlxIng.amount.string ?? "適量",
                    unit: mlxIng.unit,
                    notes: mlxIng.notes
                )
            }

            // 轉換 instructions
            let instructions = recipeResponse.instructions.map { mlxInst in
                Instruction(
                    step: mlxInst.step,
                    text: mlxInst.text,
                    time: mlxInst.time,
                    temperature: mlxInst.temperature,
                    tips: mlxInst.tips
                )
            }

            // 轉換 nutrition info
            let nutrition: NutritionInfo? = recipeResponse.nutritionInfo.map { n in
                NutritionInfo(
                    calories: n.calories,
                    protein: n.protein?.string,
                    carbs: n.carbs?.string,
                    fat: n.fat?.string,
                    fiber: n.fiber?.string,
                    sugar: n.sugar?.string,
                    sodium: n.sodium?.string
                )
            }

            return Recipe(
                title: recipeResponse.title,
                description: "\(recipeResponse.description) (MLX 生成，耗時 \(String(format: "%.1f", duration))秒)",
                prepTime: recipeResponse.prepTime,
                cookTime: recipeResponse.cookTime,
                servings: recipeResponse.servings,
                difficulty: recipeDifficulty,
                ingredients: ingredients,
                instructions: instructions,
                tags: (recipeResponse.tags ?? []) + ["MLX Generated"],
                nutritionInfo: nutrition
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

// MARK: - JSON Response Model (和 Ollama 相同的結構)

private struct RecipeResponse: Codable {
    let title: String
    let description: String
    let prepTime: Int
    let cookTime: Int
    let servings: Int
    let difficulty: String
    let ingredients: [MLXIngredient]
    let instructions: [MLXInstruction]
    let tags: [String]?
    let nutritionInfo: MLXNutritionInfo?
}

private struct MLXIngredient: Codable {
    let name: String
    let amount: FlexibleStringOrInt
    let unit: String?
    let notes: String?
}

private struct MLXInstruction: Codable {
    let step: Int
    let text: String
    let time: Int?
    let temperature: String?
    let tips: String?
}

private struct MLXNutritionInfo: Codable {
    let calories: Int?
    let protein: FlexibleStringOrInt?
    let carbs: FlexibleStringOrInt?
    let fat: FlexibleStringOrInt?
    let fiber: FlexibleStringOrInt?
    let sugar: FlexibleStringOrInt?
    let sodium: FlexibleStringOrInt?
}

// 支援數字或字串的靈活類型
private struct FlexibleStringOrInt: Codable {
    let stringValue: String?
    let intValue: Int?
    
    init(string: String?, int: Int?) {
        self.stringValue = string
        self.intValue = int
    }
    
    var string: String? {
        return stringValue ?? (intValue != nil ? String(intValue!) : nil)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringVal = try? container.decode(String.self) {
            self.stringValue = stringVal
            self.intValue = nil
        } else if let intVal = try? container.decode(Int.self) {
            self.intValue = intVal
            self.stringValue = String(intVal)
        } else if let doubleVal = try? container.decode(Double.self) {
            self.intValue = Int(doubleVal)
            self.stringValue = String(Int(doubleVal))
        } else {
            self.stringValue = nil
            self.intValue = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let stringVal = stringValue {
            try container.encode(stringVal)
        } else if let intVal = intValue {
            try container.encode(intVal)
        }
    }
}

// MARK: - Timeout Helper

/// 為 async 操作添加超時限制
@available(iOS 16.0, macOS 14.0, *)
private func withTimeout<T>(seconds: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        // 添加實際操作
        group.addTask {
            try await operation()
        }

        // 添加超時檢查
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw MLXError.generationFailed("操作超時（\(Int(seconds))秒）")
        }

        // 返回第一個完成的結果
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
