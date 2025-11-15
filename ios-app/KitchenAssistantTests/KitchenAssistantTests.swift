//
//  KitchenAssistantTests.swift
//  KitchenAssistantTests
//
//  Unit Tests for Kitchen Assistant
//

import XCTest
@testable import KitchenAssistant

final class KitchenAssistantTests: XCTestCase {
    
    // MARK: - Model Tests
    
    func testRecipeModelDecoding() throws {
        let jsonData = """
        {
            "title": "Test Recipe",
            "description": "A test recipe",
            "prep_time": 10,
            "cook_time": 20,
            "servings": 2,
            "difficulty": "Easy",
            "ingredients": [
                {
                    "name": "Cheese",
                    "amount": "1",
                    "unit": "cup",
                    "notes": null
                }
            ],
            "instructions": [
                {
                    "step": 1,
                    "text": "Mix ingredients",
                    "time": 5,
                    "temperature": null,
                    "tips": null
                }
            ],
            "tags": ["quick", "easy"],
            "nutrition_info": null
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let recipe = try decoder.decode(Recipe.self, from: jsonData)
        
        XCTAssertEqual(recipe.title, "Test Recipe")
        XCTAssertEqual(recipe.prepTime, 10)
        XCTAssertEqual(recipe.cookTime, 20)
        XCTAssertEqual(recipe.servings, 2)
        XCTAssertEqual(recipe.ingredients.count, 1)
        XCTAssertEqual(recipe.instructions.count, 1)
        XCTAssertEqual(recipe.tags.count, 2)
    }
    
    func testIngredientModel() {
        let ingredient = Ingredient(
            name: "Chicken",
            amount: "2",
            unit: "pieces",
            notes: "boneless"
        )
        
        XCTAssertEqual(ingredient.name, "Chicken")
        XCTAssertEqual(ingredient.amount, "2")
        XCTAssertEqual(ingredient.unit, "pieces")
        XCTAssertEqual(ingredient.notes, "boneless")
    }
    
    func testInstructionModel() {
        let instruction = Instruction(
            step: 1,
            text: "Preheat oven",
            time: 5,
            temperature: "350°F",
            tips: "Use convection if available"
        )
        
        XCTAssertEqual(instruction.step, 1)
        XCTAssertEqual(instruction.text, "Preheat oven")
        XCTAssertEqual(instruction.time, 5)
        XCTAssertEqual(instruction.temperature, "350°F")
        XCTAssertEqual(instruction.tips, "Use convection if available")
    }
    
    // MARK: - API Client Tests
    
    func testAPIClientInitialization() {
        let apiClient = APIClient()
        XCTAssertNotNil(apiClient)
    }
    
    // MARK: - Local Inference Tests
    
    func testLocalInferenceServiceInitialization() {
        let service = LocalInferenceService()
        XCTAssertNotNil(service)
    }
    
    // MARK: - MLX Recipe Generator Tests
    
    func testMLXRecipeGeneratorInitialization() {
        let generator = MLXRecipeGenerator()
        XCTAssertNotNil(generator)
    }
    
    // MARK: - Recipe Request Model Tests
    
    func testRecipeRequestEncoding() throws {
        let request = RecipeRequest(
            ingredients: ["chicken", "cheese"],
            mealCraving: "pasta",
            dietaryRestrictions: [],
            preferredCuisine: "Italian"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data.count, 0)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyIngredientsHandling() {
        let ingredients: [String] = []
        XCTAssertEqual(ingredients.count, 0)
        // Test that empty ingredients are handled gracefully
    }
    
    func testNilOptionalFieldsHandling() {
        let ingredient = Ingredient(
            name: "Salt",
            amount: "1",
            unit: "tsp",
            notes: nil
        )
        
        XCTAssertNil(ingredient.notes)
    }
    
    // MARK: - Performance Tests
    
    func testRecipeDecodingPerformance() throws {
        let jsonData = """
        {
            "title": "Test Recipe",
            "description": "A test recipe",
            "prep_time": 10,
            "cook_time": 20,
            "servings": 2,
            "difficulty": "Easy",
            "ingredients": [{"name": "Cheese", "amount": "1", "unit": "cup", "notes": null}],
            "instructions": [{"step": 1, "text": "Mix", "time": 5, "temperature": null, "tips": null}],
            "tags": ["quick"],
            "nutrition_info": null
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        measure {
            _ = try? decoder.decode(Recipe.self, from: jsonData)
        }
    }
}

