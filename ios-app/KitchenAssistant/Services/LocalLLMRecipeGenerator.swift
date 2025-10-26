import Foundation

/// 使用本地 Ollama API 生成食譜（透過 localhost:11434）
class LocalLLMRecipeGenerator {

    // MARK: - Properties
    
    private let ollamaBaseURL = "http://localhost:11434"
    private let modelName = "qwen2.5:3b"

    // MARK: - Initialization

    init() {
        print("============================================================")
        print("🚀🚀🚀 LocalLLMRecipeGenerator 初始化完成 🚀🚀🚀")
        print("📍 使用 Ollama API: \(ollamaBaseURL)")
        print("🤖 模型: \(modelName)")
        print("============================================================")
    }

    // MARK: - Public Methods

    /// 生成食譜
    func generateRecipe(
        ingredients: [String],
        mealCraving: String,
        dietaryRestrictions: [String] = [],
        preferredCuisine: String = "Any"
    ) async throws -> Recipe {

        print("🤖 使用本地 Ollama LLM 生成食譜...")
        print("  - 食材: \(ingredients)")
        print("  - 想吃: \(mealCraving)")

        let startTime = CFAbsoluteTimeGetCurrent()

        // 建立 prompt
        let prompt = buildPrompt(
            ingredients: ingredients,
            mealCraving: mealCraving,
            dietaryRestrictions: dietaryRestrictions,
            preferredCuisine: preferredCuisine
        )

        do {
            // 呼叫 Ollama API
            print("🔄 正在呼叫 Ollama API (\(ollamaBaseURL))...")
            let response = try await callOllamaAPI(prompt: prompt)

            let endTime = CFAbsoluteTimeGetCurrent()
            print("⏱️ LLM 生成時間: \(String(format: "%.2f", endTime - startTime))秒")
            print("📄 LLM Response length: \(response.count) characters")

            // 解析 JSON response
            if let recipe = parseRecipeFromResponse(response) {
                print("✅ 食譜生成成功: \(recipe.title)")
                return recipe
            } else {
                print("⚠️ 無法解析 LLM response，使用 fallback")
                return generateFallbackRecipe(
                    ingredients: ingredients,
                    mealCraving: mealCraving,
                    dietaryRestrictions: dietaryRestrictions,
                    preferredCuisine: preferredCuisine
                )
            }
        } catch {
            print("❌ Ollama API 呼叫失敗: \(error)")
            print("⚠️ 使用 fallback recipe generator")
            return generateFallbackRecipe(
                ingredients: ingredients,
                mealCraving: mealCraving,
                dietaryRestrictions: dietaryRestrictions,
                preferredCuisine: preferredCuisine
            )
        }
    }

    // MARK: - Private Methods - Ollama API
    
    private func callOllamaAPI(prompt: String) async throws -> String {
        let url = URL(string: "\(ollamaBaseURL)/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
            throw LLMError.generationFailed("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw LLMError.generationFailed("HTTP \(httpResponse.statusCode)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = json["response"] as? String else {
            throw LLMError.invalidResponse
        }
        
        return responseText
    }

    // MARK: - Prompt Building

    private func buildPrompt(
        ingredients: [String],
        mealCraving: String,
        dietaryRestrictions: [String],
        preferredCuisine: String
    ) -> String {
        let ingredientsList = ingredients.joined(separator: ", ")
        let restrictionsText = dietaryRestrictions.isEmpty ? "None" : dietaryRestrictions.joined(separator: ", ")

        return """
        You are a professional chef AI. Create a detailed recipe for "\(mealCraving)" using these ingredients: \(ingredientsList)

        CRITICAL RULES - FOLLOW STRICTLY:

        1. INGREDIENT UNITS (use CORRECT units for each ingredient type):
           - Cheese: "cup", "oz", "g" (NEVER "clove" - that's for garlic!)
           - Garlic: "clove", "tsp", "tbsp"
           - Vegetables: "cup", "whole", "pieces"
           - Liquids: "cup", "ml", "tbsp", "tsp"
           - Meat: "lb", "oz", "g", "pieces"
           - Spices: "tsp", "tbsp", "pinch"

        2. DISH TYPE VALIDATION:
           - If dish is "\(mealCraving.lowercased())":
             * For DESSERTS (cake, cookies, pie): Use SWEET ingredients (sugar, vanilla, chocolate, butter, eggs, flour)
             * For SAVORY dishes (pasta, stir-fry, soup): Use SAVORY ingredients (salt, pepper, garlic, oil, herbs)
             * NEVER mix sweet/savory incorrectly (e.g., NO salt in cheesecake!)

        3. COOKING INSTRUCTIONS:
           - Must match the dish type exactly
           - Pasta: boil water, cook pasta, make sauce, combine
           - Cake: mix dry, mix wet, combine, bake
           - Stir-fry: prep ingredients, heat wok, stir-fry, season
           - Each step must be specific, not generic

        4. REALISTIC AMOUNTS:
           - Servings: 2-6 people
           - Prep time: 5-30 minutes
           - Cook time: 10-60 minutes (0 for salads/no-cook)

        EXAMPLE - Cheese Cake (CORRECT):
        {
          "title": "Classic New York Cheesecake",
          "description": "Rich and creamy cheesecake with graham cracker crust",
          "prepTime": 20,
          "cookTime": 60,
          "servings": 8,
          "difficulty": "Medium",
          "ingredients": [
            {"name": "Cream cheese", "amount": "16", "unit": "oz", "notes": "softened"},
            {"name": "Sugar", "amount": "3/4", "unit": "cup", "notes": null},
            {"name": "Eggs", "amount": "3", "unit": "whole", "notes": "room temperature"},
            {"name": "Vanilla extract", "amount": "1", "unit": "tsp", "notes": null},
            {"name": "Graham crackers", "amount": "1.5", "unit": "cups", "notes": "crushed"}
          ],
          "instructions": [
            {"step": 1, "text": "Preheat oven to 325°F. Make crust by mixing crushed graham crackers with melted butter.", "time": 5, "temperature": "325°F", "tips": "Press firmly into pan"},
            {"step": 2, "text": "Beat cream cheese until smooth. Add sugar and beat until fluffy.", "time": 5, "temperature": null, "tips": "No lumps"},
            {"step": 3, "text": "Add eggs one at a time, beating well after each. Add vanilla.", "time": 3, "temperature": null, "tips": "Don't overmix"},
            {"step": 4, "text": "Pour filling over crust. Bake for 50-60 minutes until edges set but center jiggles.", "time": 60, "temperature": "325°F", "tips": "Don't open oven door"},
            {"step": 5, "text": "Cool completely, then refrigerate 4 hours before serving.", "time": 240, "temperature": null, "tips": "Patience is key"}
          ],
          "tags": ["Dessert", "Baked", "Classic"],
          "nutritionInfo": {"calories": 380, "protein": "7g", "carbs": "32g", "fat": "26g", "fiber": "0g", "sugar": "24g", "sodium": "320mg"}
        }

        NOW CREATE YOUR RECIPE:
        - Dish Type: \(mealCraving)
        - Available Ingredients: \(ingredientsList)
        - Dietary Restrictions: \(restrictionsText)
        - Preferred Cuisine: \(preferredCuisine)

        REMEMBER:
        - Use CORRECT units for each ingredient (cheese = cups/oz, NOT cloves!)
        - Match ingredients to dish type (sweet for desserts, savory for mains)
        - Write specific instructions, not generic ones
        - Return ONLY valid JSON, no extra text

        JSON response:
        """
    }

    // MARK: - Response Parsing

    private func parseRecipeFromResponse(_ response: String) -> Recipe? {
        // 提取 JSON（移除可能的 markdown 代碼塊）
        var jsonString = response.trimmingCharacters(in: .whitespacesAndNewlines)

        // 移除 markdown code blocks
        if jsonString.hasPrefix("```json") {
            jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
        }
        if jsonString.hasPrefix("```") {
            jsonString = jsonString.replacingOccurrences(of: "```", with: "")
        }
        if jsonString.hasSuffix("```") {
            jsonString = String(jsonString.dropLast(3))
        }
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        // 嘗試找到第一個 { 和最後一個 }
        if let firstBrace = jsonString.firstIndex(of: "{"),
           let lastBrace = jsonString.lastIndex(of: "}") {
            jsonString = String(jsonString[firstBrace...lastBrace])
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            print("❌ 無法將 response 轉換為 data")
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let recipeResponse = try decoder.decode(LLMRecipeResponse.self, from: jsonData)
            let recipe = recipeResponse.toRecipe()

            // ✅ 驗證食譜合理性
            if validateRecipe(recipe) {
                return recipe
            } else {
                print("⚠️ Recipe validation failed - 食譜不合理，使用 fallback")
                return nil
            }
        } catch {
            print("❌ JSON 解析失敗: \(error)")
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📄 Response preview: \(jsonString.prefix(500))")
            }
            return nil
        }
    }

    // MARK: - Recipe Validation

    /// 驗證食譜是否合理
    private func validateRecipe(_ recipe: Recipe) -> Bool {
        var isValid = true

        // 1. 檢查食材單位是否合理
        for ingredient in recipe.ingredients {
            let name = ingredient.name.lowercased()
            let unit = ingredient.unit?.lowercased() ?? ""

            // ❌ Cheese 不能用 "clove"
            if name.contains("cheese") && unit.contains("clove") {
                print("❌ Validation failed: Cheese 使用了錯誤的單位 '\(unit)'")
                isValid = false
            }

            // ❌ Garlic 以外的食材不應該用 "clove"
            if !name.contains("garlic") && unit.contains("clove") {
                print("❌ Validation failed: '\(name)' 不應該用單位 'clove'")
                isValid = false
            }
        }

        // 2. 檢查甜點是否使用了不當的調味料
        let title = recipe.title.lowercased()
        let isCake = title.contains("cake") || title.contains("dessert") || title.contains("cookie") || title.contains("pie")

        if isCake {
            for ingredient in recipe.ingredients {
                let name = ingredient.name.lowercased()

                // ❌ 甜點不應該有鹹味調味料
                if name.contains("salt") && !name.contains("salted") {
                    print("⚠️ Warning: 甜點 '\(recipe.title)' 包含 salt（可能不合理）")
                }
                if name.contains("pepper") || name.contains("soy sauce") {
                    print("❌ Validation failed: 甜點不應該包含 '\(name)'")
                    isValid = false
                }
            }
        }

        // 3. 檢查是否有合理的烹飪時間
        if recipe.prepTime < 0 || recipe.cookTime < 0 {
            print("❌ Validation failed: 烹飪時間不能為負數")
            isValid = false
        }

        if recipe.prepTime > 120 || recipe.cookTime > 300 {
            print("⚠️ Warning: 烹飪時間過長（可能不合理）")
        }

        // 4. 檢查是否有足夠的步驟
        if recipe.instructions.count < 2 {
            print("❌ Validation failed: 步驟太少（至少需要 2 個步驟）")
            isValid = false
        }

        // 5. 檢查是否有食材
        if recipe.ingredients.isEmpty {
            print("❌ Validation failed: 沒有任何食材")
            isValid = false
        }

        if isValid {
            print("✅ Recipe validation passed: \(recipe.title)")
        }

        return isValid
    }

    // MARK: - Fallback Recipe Generation

    private func generateFallbackRecipe(
        ingredients: [String],
        mealCraving: String,
        dietaryRestrictions: [String],
        preferredCuisine: String
    ) -> Recipe {

        let mainIngredient = ingredients.first ?? "Vegetable"
        let cravingLower = mealCraving.lowercased()

        // 根據 meal craving 決定料理類型和步驟
        let recipeConfig = getRecipeConfig(for: cravingLower, mainIngredient: mainIngredient)

        let title = "\(preferredCuisine != "Any" ? preferredCuisine : recipeConfig.adjective) \(mainIngredient) \(mealCraving.capitalized)"

        var recipeIngredients: [Ingredient] = []
        for (index, ingredient) in ingredients.prefix(5).enumerated() {
            recipeIngredients.append(Ingredient(
                name: ingredient,
                amount: recipeConfig.amounts[min(index, recipeConfig.amounts.count - 1)],
                unit: recipeConfig.units[min(index, recipeConfig.units.count - 1)],
                notes: index == 0 ? "main ingredient" : nil
            ))
        }

        recipeIngredients.append(contentsOf: recipeConfig.extraIngredients)

        var tags = ["Homemade", "Fresh Ingredients", "Fallback Mode"]
        tags.append(recipeConfig.category)
        if preferredCuisine != "Any" { tags.append(preferredCuisine) }
        if dietaryRestrictions.contains("vegetarian") { tags.append("Vegetarian") }

        return Recipe(
            title: title,
            description: "A delicious \(mealCraving.lowercased()) made with fresh \(mainIngredient.lowercased()). \(recipeConfig.description)",
            prepTime: recipeConfig.prepTime,
            cookTime: recipeConfig.cookTime,
            servings: 4,
            difficulty: recipeConfig.difficulty,
            ingredients: recipeIngredients,
            instructions: recipeConfig.instructions,
            tags: tags,
            nutritionInfo: recipeConfig.nutrition
        )
    }

    // 根據料理類型生成不同配置
    private func getRecipeConfig(for craving: String, mainIngredient: String) -> RecipeConfig {
        // Fried Rice
        if craving.contains("fried rice") || craving.contains("rice") {
            return RecipeConfig(
                adjective: "Golden",
                category: "Asian",
                description: "Perfect for using leftover rice. Quick, easy, and full of flavor!",
                amounts: ["2", "1", "1/2", "1", "1"],
                units: ["cups", "cup", "cup", "cup", "cup"],
                extraIngredients: [
                    Ingredient(name: "Cooked rice", amount: "3", unit: "cups", notes: "day-old rice works best"),
                    Ingredient(name: "Soy sauce", amount: "3", unit: "tbsp", notes: nil),
                    Ingredient(name: "Eggs", amount: "2", unit: "whole", notes: "beaten"),
                    Ingredient(name: "Vegetable oil", amount: "2", unit: "tbsp", notes: nil),
                    Ingredient(name: "Green onions", amount: "2", unit: "stalks", notes: "chopped")
                ],
                instructions: [
                    Instruction(step: 1, text: "Prepare and chop all vegetables and ingredients.", time: 8, temperature: nil, tips: "Use day-old rice for best results"),
                    Instruction(step: 2, text: "Heat oil in a wok or large pan over high heat.", time: 2, temperature: "High", tips: "Wok should be smoking hot"),
                    Instruction(step: 3, text: "Scramble the eggs and set aside.", time: 2, temperature: nil, tips: "Don't overcook the eggs"),
                    Instruction(step: 4, text: "Stir-fry vegetables until just tender.", time: 3, temperature: "High", tips: "Keep ingredients moving"),
                    Instruction(step: 5, text: "Add rice and break up any clumps, stir-fry for 3-4 minutes.", time: 4, temperature: nil, tips: "Rice should be slightly crispy"),
                    Instruction(step: 6, text: "Add soy sauce and scrambled eggs, toss everything together.", time: 2, temperature: nil, tips: "Taste and adjust seasoning"),
                    Instruction(step: 7, text: "Garnish with green onions and serve hot!", time: nil, temperature: nil, tips: "Great with sriracha on top")
                ],
                prepTime: 10,
                cookTime: 15,
                difficulty: .easy,
                nutrition: NutritionInfo(calories: 380, protein: "12g", carbs: "58g", fat: "12g", fiber: "3g", sugar: "4g", sodium: "680mg")
            )
        }

        // Steak
        else if craving.contains("steak") || craving.contains("beef") {
            return RecipeConfig(
                adjective: "Perfect",
                category: "American",
                description: "Restaurant-quality steak made at home with a beautiful crust.",
                amounts: ["2", "1", "1/2", "1/4", "1"],
                units: ["pieces", "cup", "cup", "cup", "cup"],
                extraIngredients: [
                    Ingredient(name: "Steak", amount: "2", unit: "pieces", notes: "1 inch thick"),
                    Ingredient(name: "Butter", amount: "2", unit: "tbsp", notes: nil),
                    Ingredient(name: "Garlic", amount: "3", unit: "cloves", notes: "smashed"),
                    Ingredient(name: "Fresh thyme", amount: "2", unit: "sprigs", notes: nil),
                    Ingredient(name: "Salt", amount: "1", unit: "tsp", notes: "kosher salt"),
                    Ingredient(name: "Black pepper", amount: "1", unit: "tsp", notes: "freshly ground")
                ],
                instructions: [
                    Instruction(step: 1, text: "Remove steak from fridge 30 minutes before cooking and pat dry.", time: 5, temperature: nil, tips: "Room temperature steak cooks more evenly"),
                    Instruction(step: 2, text: "Season both sides generously with salt and pepper.", time: 2, temperature: nil, tips: "Don't be shy with seasoning"),
                    Instruction(step: 3, text: "Heat a cast iron skillet over high heat until smoking.", time: 5, temperature: "High", tips: "Pan must be very hot"),
                    Instruction(step: 4, text: "Sear steak for 3-4 minutes without moving it.", time: 4, temperature: "High", tips: "This creates the crust"),
                    Instruction(step: 5, text: "Flip and sear the other side for 3-4 minutes.", time: 4, temperature: "High", tips: nil),
                    Instruction(step: 6, text: "Add butter, garlic, and thyme. Baste steak with melted butter.", time: 2, temperature: "Medium", tips: "Tilt pan to pool butter"),
                    Instruction(step: 7, text: "Remove from heat and let rest for 5 minutes before slicing.", time: 5, temperature: nil, tips: "Resting keeps juices inside")
                ],
                prepTime: 35,
                cookTime: 12,
                difficulty: .medium,
                nutrition: NutritionInfo(calories: 450, protein: "42g", carbs: "2g", fat: "28g", fiber: "0g", sugar: "0g", sodium: "520mg")
            )
        }

        // Pasta
        else if craving.contains("pasta") || craving.contains("spaghetti") {
            return RecipeConfig(
                adjective: "Classic",
                category: "Italian",
                description: "Simple yet delicious pasta with fresh ingredients.",
                amounts: ["1", "1/2", "1", "1/2", "1/4"],
                units: ["cup", "cup", "cup", "cup", "cup"],
                extraIngredients: [
                    Ingredient(name: "Pasta", amount: "12", unit: "oz", notes: "your choice"),
                    Ingredient(name: "Olive oil", amount: "3", unit: "tbsp", notes: "extra virgin"),
                    Ingredient(name: "Garlic", amount: "4", unit: "cloves", notes: "minced"),
                    Ingredient(name: "Cherry tomatoes", amount: "2", unit: "cups", notes: "halved"),
                    Ingredient(name: "Fresh basil", amount: "1/4", unit: "cup", notes: "chopped"),
                    Ingredient(name: "Parmesan", amount: "1/2", unit: "cup", notes: "grated")
                ],
                instructions: [
                    Instruction(step: 1, text: "Bring a large pot of salted water to boil.", time: 5, temperature: nil, tips: "Water should taste like the sea"),
                    Instruction(step: 2, text: "Cook pasta according to package directions until al dente.", time: 10, temperature: nil, tips: "Reserve 1 cup pasta water"),
                    Instruction(step: 3, text: "Meanwhile, heat olive oil in a large pan over medium heat.", time: 2, temperature: "Medium", tips: nil),
                    Instruction(step: 4, text: "Sauté garlic until fragrant, about 30 seconds.", time: 1, temperature: nil, tips: "Don't let garlic burn"),
                    Instruction(step: 5, text: "Add tomatoes and cook until they start to break down.", time: 5, temperature: nil, tips: "Some tomatoes should burst"),
                    Instruction(step: 6, text: "Add drained pasta and toss. Add pasta water to create sauce.", time: 2, temperature: nil, tips: "Pasta water helps bind sauce"),
                    Instruction(step: 7, text: "Remove from heat, add basil and parmesan, toss and serve!", time: nil, temperature: nil, tips: "Finish with extra parmesan")
                ],
                prepTime: 8,
                cookTime: 18,
                difficulty: .easy,
                nutrition: NutritionInfo(calories: 420, protein: "16g", carbs: "62g", fat: "14g", fiber: "4g", sugar: "6g", sodium: "380mg")
            )
        }

        // Salad
        else if craving.contains("salad") {
            return RecipeConfig(
                adjective: "Fresh",
                category: "Healthy",
                description: "Light, crisp, and full of nutrients. Perfect for a quick meal!",
                amounts: ["2", "1", "1", "1/2", "1/2"],
                units: ["cups", "cup", "cup", "cup", "cup"],
                extraIngredients: [
                    Ingredient(name: "Mixed greens", amount: "4", unit: "cups", notes: nil),
                    Ingredient(name: "Cherry tomatoes", amount: "1", unit: "cup", notes: "halved"),
                    Ingredient(name: "Cucumber", amount: "1", unit: "whole", notes: "diced"),
                    Ingredient(name: "Olive oil", amount: "3", unit: "tbsp", notes: nil),
                    Ingredient(name: "Lemon juice", amount: "2", unit: "tbsp", notes: "fresh"),
                    Ingredient(name: "Honey", amount: "1", unit: "tsp", notes: nil)
                ],
                instructions: [
                    Instruction(step: 1, text: "Wash and dry all vegetables thoroughly.", time: 5, temperature: nil, tips: "Use a salad spinner if available"),
                    Instruction(step: 2, text: "Chop vegetables into bite-sized pieces.", time: 5, temperature: nil, tips: "Keep cuts uniform"),
                    Instruction(step: 3, text: "Make dressing: whisk together olive oil, lemon juice, honey, salt, and pepper.", time: 2, temperature: nil, tips: "Taste and adjust to preference"),
                    Instruction(step: 4, text: "In a large bowl, combine all chopped vegetables.", time: 2, temperature: nil, tips: "Toss gently"),
                    Instruction(step: 5, text: "Drizzle dressing over salad just before serving.", time: 1, temperature: nil, tips: "Don't overdress the salad"),
                    Instruction(step: 6, text: "Serve immediately for maximum crispness!", time: nil, temperature: nil, tips: "Add protein for a complete meal")
                ],
                prepTime: 12,
                cookTime: 0,
                difficulty: .easy,
                nutrition: NutritionInfo(calories: 180, protein: "4g", carbs: "18g", fat: "12g", fiber: "6g", sugar: "10g", sodium: "120mg")
            )
        }

        // Default: Stir-fry
        else {
            return RecipeConfig(
                adjective: "Tasty",
                category: "Quick & Easy",
                description: "A versatile stir-fry that works with any ingredients!",
                amounts: ["2", "1", "1", "1/2", "1/2"],
                units: ["cups", "cup", "cup", "cup", "cup"],
                extraIngredients: [
                    Ingredient(name: "Soy sauce", amount: "2", unit: "tbsp", notes: nil),
                    Ingredient(name: "Vegetable oil", amount: "2", unit: "tbsp", notes: nil),
                    Ingredient(name: "Garlic", amount: "2", unit: "cloves", notes: "minced"),
                    Ingredient(name: "Ginger", amount: "1", unit: "tsp", notes: "minced"),
                    Ingredient(name: "Sesame oil", amount: "1", unit: "tsp", notes: nil)
                ],
                instructions: [
                    Instruction(step: 1, text: "Prepare all ingredients: wash, chop, and organize.", time: 10, temperature: nil, tips: "Mise en place is key for stir-fry"),
                    Instruction(step: 2, text: "Heat oil in a wok or large pan over high heat.", time: 2, temperature: "High", tips: "Pan should be very hot"),
                    Instruction(step: 3, text: "Add garlic and ginger, stir-fry for 30 seconds.", time: 1, temperature: nil, tips: "Keep moving to prevent burning"),
                    Instruction(step: 4, text: "Add main ingredients, stir-fry until just tender.", time: 8, temperature: "High", tips: "Don't overcook vegetables"),
                    Instruction(step: 5, text: "Add soy sauce and toss everything together.", time: 2, temperature: nil, tips: "Adjust seasoning to taste"),
                    Instruction(step: 6, text: "Drizzle with sesame oil and serve hot over rice!", time: nil, temperature: nil, tips: "Garnish with sesame seeds")
                ],
                prepTime: 12,
                cookTime: 13,
                difficulty: .easy,
                nutrition: NutritionInfo(calories: 220, protein: "10g", carbs: "24g", fat: "10g", fiber: "5g", sugar: "6g", sodium: "580mg")
            )
        }
    }

    // Recipe 配置結構
    private struct RecipeConfig {
        let adjective: String
        let category: String
        let description: String
        let amounts: [String]
        let units: [String]
        let extraIngredients: [Ingredient]
        let instructions: [Instruction]
        let prepTime: Int
        let cookTime: Int
        let difficulty: Recipe.Difficulty
        let nutrition: NutritionInfo
    }
}

// MARK: - LLM Response Structures

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

// MARK: - Error Types

enum LLMError: Error, LocalizedError {
    case modelNotLoaded
    case modelLoadingFailed(String)
    case generationFailed(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Model is not loaded yet."
        case .modelLoadingFailed(let message):
            return "Failed to load model: \(message)"
        case .generationFailed(let message):
            return "Generation failed: \(message)"
        case .invalidResponse:
            return "Invalid response from model"
        }
    }
}
