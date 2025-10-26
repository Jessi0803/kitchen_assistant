import Foundation
import SwiftUI

/// 支援網路連接的 Ollama 生成器（可用於實機測試）
class NetworkOllamaGenerator: ObservableObject {
    
    // MARK: - Properties
    
    @Published var ollamaServerURL: String = "http://localhost:11434"
    
    private let modelName = "qwen2.5:3b"
    
    // MARK: - Initialization
    
    init() {
        print("✅ NetworkOllamaGenerator 初始化")
        autoDetectOllamaServer()
    }
    
    // MARK: - Public Methods
    
    /// 生成食譜
    func generateRecipe(
        ingredients: [String],
        mealCraving: String,
        dietaryRestrictions: [String] = [],
        preferredCuisine: String = "Any"
    ) async throws -> Recipe {
        
        print("🤖 連接到 Ollama: \(ollamaServerURL)")
        
        // 先測試連接
        let isReachable = await testConnection()
        guard isReachable else {
            throw OllamaError.serverNotReachable(ollamaServerURL)
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let prompt = buildPrompt(
            ingredients: ingredients,
            mealCraving: mealCraving,
            dietaryRestrictions: dietaryRestrictions,
            preferredCuisine: preferredCuisine
        )
        
        do {
            let response = try await callOllamaAPI(prompt: prompt)
            let endTime = CFAbsoluteTimeGetCurrent()
            print("⏱️ LLM 生成時間: \(String(format: "%.2f", endTime - startTime))秒")
            
            if let recipe = parseRecipeFromResponse(response) {
                print("✅ 食譜生成成功: \(recipe.title)")
                return recipe
            } else {
                print("⚠️ 無法解析 LLM response，使用 fallback")
                return generateFallbackRecipe(
                    ingredients: ingredients,
                    mealCraving: mealCraving
                )
            }
        } catch {
            print("❌ Ollama API 呼叫失敗: \(error)")
            throw error
        }
    }
    
    /// 測試 Ollama 連接
    func testConnection() async -> Bool {
        let url = URL(string: "\(ollamaServerURL)/api/tags")!
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            print("❌ Ollama 連接測試失敗: \(error)")
            return false
        }
    }
    
    /// 自動偵測 Ollama 伺服器
    private func autoDetectOllamaServer() {
        Task {
            // 嘗試 localhost（Simulator）
            if await testConnectionTo("http://localhost:11434") {
                ollamaServerURL = "http://localhost:11434"
                print("✅ 偵測到 localhost Ollama")
                return
            }
            
            // 嘗試常見的 Mac IP（實機測試）
            let commonIPs = [
                "http://192.168.1.1:11434",
                "http://192.168.0.1:11434",
                "http://10.0.0.1:11434"
            ]
            
            for ip in commonIPs {
                if await testConnectionTo(ip) {
                    ollamaServerURL = ip
                    print("✅ 偵測到網路 Ollama: \(ip)")
                    return
                }
            }
            
            print("⚠️ 未偵測到 Ollama 伺服器")
        }
    }
    
    private func testConnectionTo(_ urlString: String) async -> Bool {
        guard let url = URL(string: "\(urlString)/api/tags") else { return false }
        
        do {
            let request = URLRequest(url: url, timeoutInterval: 2.0)
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func callOllamaAPI(prompt: String) async throws -> String {
        let url = URL(string: "\(ollamaServerURL)/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60.0  // LLM 生成可能需要較長時間
        
        let requestBody: [String: Any] = [
            "model": modelName,
            "prompt": prompt,
            "stream": false,
            "options": [
                "temperature": 0.7,
                "num_predict": 2048
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OllamaError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = json["response"] as? String else {
            throw OllamaError.invalidResponse
        }
        
        return responseText
    }
    
    private func buildPrompt(
        ingredients: [String],
        mealCraving: String,
        dietaryRestrictions: [String],
        preferredCuisine: String
    ) -> String {
        let ingredientsList = ingredients.joined(separator: ", ")
        let restrictionsText = dietaryRestrictions.isEmpty ? "None" : dietaryRestrictions.joined(separator: ", ")
        
        return """
        You are a professional chef AI. Create a detailed recipe.
        
        Available Ingredients: \(ingredientsList)
        Dish Type: \(mealCraving)
        Dietary Restrictions: \(restrictionsText)
        Preferred Cuisine: \(preferredCuisine)
        
        Return ONLY a JSON object with this exact structure:
        {
          "title": "Recipe Name",
          "description": "Brief description",
          "prepTime": 15,
          "cookTime": 30,
          "servings": 4,
          "difficulty": "Easy",
          "ingredients": [
            {"name": "ingredient", "amount": "1", "unit": "cup", "notes": null}
          ],
          "instructions": [
            {"step": 1, "text": "instruction", "time": 5, "temperature": null, "tips": null}
          ],
          "tags": ["tag1"],
          "nutritionInfo": {
            "calories": 350,
            "protein": "20g",
            "carbs": "40g",
            "fat": "15g",
            "fiber": "5g",
            "sugar": "5g",
            "sodium": "400mg"
          }
        }
        """
    }
    
    private func parseRecipeFromResponse(_ response: String) -> Recipe? {
        var jsonString = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 移除 markdown code blocks
        if jsonString.hasPrefix("```json") || jsonString.hasPrefix("```") {
            jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
                                   .replacingOccurrences(of: "```", with: "")
                                   .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 提取 JSON
        if let firstBrace = jsonString.firstIndex(of: "{"),
           let lastBrace = jsonString.lastIndex(of: "}") {
            jsonString = String(jsonString[firstBrace...lastBrace])
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        
        do {
            let decoder = JSONDecoder()
            let recipeResponse = try decoder.decode(LLMRecipeResponse.self, from: jsonData)
            return recipeResponse.toRecipe()
        } catch {
            print("❌ JSON 解析失敗: \(error)")
            return nil
        }
    }
    
    private func generateFallbackRecipe(
        ingredients: [String],
        mealCraving: String
    ) -> Recipe {
        let mainIngredient = ingredients.first ?? "Mixed Ingredients"
        
        return Recipe(
            title: "\(mainIngredient) \(mealCraving)",
            description: "A simple recipe using available ingredients.",
            prepTime: 15,
            cookTime: 30,
            servings: 4,
            difficulty: .easy,
            ingredients: ingredients.map { 
                Ingredient(name: $0, amount: "1", unit: "portion", notes: nil) 
            },
            instructions: [
                Instruction(step: 1, text: "Prepare all ingredients.", time: 5, temperature: nil, tips: nil),
                Instruction(step: 2, text: "Cook according to your preference.", time: 25, temperature: nil, tips: nil)
            ],
            tags: ["Simple", "Fallback"],
            nutritionInfo: nil
        )
    }
}

// MARK: - Error Types

enum OllamaError: LocalizedError {
    case serverNotReachable(String)
    case invalidResponse
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .serverNotReachable(let url):
            return "Cannot reach Ollama server at \(url). Make sure it's running and accessible."
        case .invalidResponse:
            return "Invalid response from Ollama server."
        case .httpError(let code):
            return "Ollama server error: HTTP \(code)"
        }
    }
}

// 重複使用現有的 LLMRecipeResponse 結構（從 LocalLLMRecipeGenerator.swift）
private struct LLMRecipeResponse: Codable {
    let title: String
    let description: String
    let prepTime: Int
    let cookTime: Int
    let servings: Int
    let difficulty: String
    let ingredients: [LLMIngredient]
    let instructions: [LLMInstruction]
    let tags: [String]?
    let nutritionInfo: LLMNutritionInfo?
    
    func toRecipe() -> Recipe {
        let recipeDifficulty: Recipe.Difficulty
        switch difficulty.lowercased() {
        case "easy": recipeDifficulty = .easy
        case "medium": recipeDifficulty = .medium
        case "hard": recipeDifficulty = .hard
        default: recipeDifficulty = .easy
        }
        
        let recipeIngredients = ingredients.map { llmIng in
            Ingredient(
                name: llmIng.name,
                amount: llmIng.amount,
                unit: llmIng.unit,
                notes: llmIng.notes
            )
        }
        
        let recipeInstructions = instructions.map { llmInst in
            Instruction(
                step: llmInst.step,
                text: llmInst.text,
                time: llmInst.time,
                temperature: llmInst.temperature,
                tips: llmInst.tips
            )
        }
        
        let nutrition: NutritionInfo? = nutritionInfo.map {
            NutritionInfo(
                calories: $0.calories,
                protein: $0.protein,
                carbs: $0.carbs,
                fat: $0.fat,
                fiber: $0.fiber,
                sugar: $0.sugar,
                sodium: $0.sodium
            )
        }
        
        return Recipe(
            title: title,
            description: description,
            prepTime: prepTime,
            cookTime: cookTime,
            servings: servings,
            difficulty: recipeDifficulty,
            ingredients: recipeIngredients,
            instructions: recipeInstructions,
            tags: tags ?? [],
            nutritionInfo: nutrition
        )
    }
}

private struct LLMIngredient: Codable {
    let name: String
    let amount: String
    let unit: String
    let notes: String?
}

private struct LLMInstruction: Codable {
    let step: Int
    let text: String
    let time: Int?
    let temperature: String?
    let tips: String?
}

private struct LLMNutritionInfo: Codable {
    let calories: Int?
    let protein: String?
    let carbs: String?
    let fat: String?
    let fiber: String?
    let sugar: String?
    let sodium: String?
}

