import Foundation

struct Recipe: Codable, Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let prepTime: Int // in minutes
    let cookTime: Int // in minutes
    let servings: Int
    let difficulty: Difficulty
    let ingredients: [Ingredient]
    let instructions: [Instruction]
    let tags: [String]
    let nutritionInfo: NutritionInfo?
    
    enum CodingKeys: String, CodingKey {
        case title, description, prepTime, cookTime, servings, difficulty
        case ingredients, instructions, tags, nutritionInfo
    }
    
    enum Difficulty: String, Codable, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        
        var color: String {
            switch self {
            case .easy: return "green"
            case .medium: return "orange"
            case .hard: return "red"
            }
        }
    }
}

struct Ingredient: Codable, Identifiable {
    let id = UUID()
    let name: String
    let amount: String
    let unit: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case name, amount, unit, notes
    }
    
    var displayText: String {
        var text = amount
        if let unit = unit, !unit.isEmpty {
            text += " \(unit)"
        }
        text += " \(name)"
        if let notes = notes, !notes.isEmpty {
            text += " (\(notes))"
        }
        return text
    }
}

struct Instruction: Codable, Identifiable {
    let id = UUID()
    let step: Int
    let text: String
    let time: Int? // in minutes
    let temperature: String?
    let tips: String?
    
    enum CodingKeys: String, CodingKey {
        case step, text, time, temperature, tips
    }
}

struct NutritionInfo: Codable {
    let calories: Int?
    let protein: String?
    let carbs: String?
    let fat: String?
    let fiber: String?
    let sugar: String?
    let sodium: String?
}

// Sample data for testing
extension Recipe {
    static let sample = Recipe(
        title: "Vegetable Stir Fry",
        description: "A quick and healthy stir fry using fresh vegetables from your fridge",
        prepTime: 15,
        cookTime: 10,
        servings: 4,
        difficulty: .easy,
        ingredients: [
            Ingredient(name: "Bell peppers", amount: "2", unit: "medium", notes: "any color"),
            Ingredient(name: "Broccoli", amount: "1", unit: "head", notes: "cut into florets"),
            Ingredient(name: "Carrots", amount: "2", unit: "large", notes: "sliced"),
            Ingredient(name: "Soy sauce", amount: "3", unit: "tbsp", notes: nil),
            Ingredient(name: "Garlic", amount: "3", unit: "cloves", notes: "minced"),
            Ingredient(name: "Ginger", amount: "1", unit: "tsp", notes: "fresh, grated"),
            Ingredient(name: "Vegetable oil", amount: "2", unit: "tbsp", notes: nil)
        ],
        instructions: [
            Instruction(step: 1, text: "Heat oil in a large wok or skillet over high heat", time: 2, temperature: "High heat", tips: "Make sure the oil is hot before adding vegetables"),
            Instruction(step: 2, text: "Add garlic and ginger, stir-fry for 30 seconds until fragrant", time: 1, temperature: nil, tips: "Don't let garlic burn"),
            Instruction(step: 3, text: "Add harder vegetables (carrots, broccoli) first, stir-fry for 3-4 minutes", time: 4, temperature: nil, tips: nil),
            Instruction(step: 4, text: "Add bell peppers and stir-fry for another 2-3 minutes", time: 3, temperature: nil, tips: "Vegetables should be crisp-tender"),
            Instruction(step: 5, text: "Add soy sauce and toss to coat all vegetables evenly", time: 1, temperature: nil, tips: "Taste and adjust seasoning"),
            Instruction(step: 6, text: "Serve immediately over rice or noodles", time: nil, temperature: nil, tips: "Best enjoyed fresh and hot")
        ],
        tags: ["Vegetarian", "Quick", "Healthy", "Asian"],
        nutritionInfo: NutritionInfo(
            calories: 180,
            protein: "6g",
            carbs: "25g",
            fat: "8g",
            fiber: "5g",
            sugar: "12g",
            sodium: "800mg"
        )
    )
}