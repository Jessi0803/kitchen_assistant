import Foundation
import UIKit

class APIClient: ObservableObject {
    // 自動偵測：Simulator 用 localhost，真機用 Mac IP
    private let baseURL: String = {
        #if targetEnvironment(simulator)
        return "http://127.0.0.1:8000"  // Simulator: 使用 localhost
        #else
        return "http://192.168.86.27:8000"  // 真機: 使用 Mac 的 IP 地址
        #endif
    }()

    private let session = URLSession.shared
    
    enum APIError: Error, LocalizedError {
        case invalidURL
        case noData
        case decodingError(Error)
        case networkError(Error)
        case serverError(Int)
        case imageProcessingError
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .noData:
                return "No data received"
            case .decodingError(let error):
                return "Decoding error: \(error.localizedDescription)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .serverError(let code):
                return "Server error: \(code)"
            case .imageProcessingError:
                return "Error processing image"
            }
        }
    }
    
    // MARK: - Detection Service
    
    func detectIngredients(in image: UIImage) async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/api/detect") else {
            throw APIError.invalidURL
        }
        
        let imageData = try prepareImageData(image)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=Boundary", forHTTPHeaderField: "Content-Type")
        request.httpBody = createMultipartBody(imageData: imageData)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        guard !data.isEmpty else {
            throw APIError.noData
        }
        
        do {
            let detectionResponse = try JSONDecoder().decode(DetectionResponse.self, from: data)
            return detectionResponse.ingredients
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - Recipe Generation Service
    
    func generateRecipe(ingredients: [String], mealCraving: String) async throws -> Recipe {
        guard let url = URL(string: "\(baseURL)/api/recipes") else {
            throw APIError.invalidURL
        }
        
        let requestBody = RecipeRequest(
            ingredients: ingredients,
            mealCraving: mealCraving,
            dietaryRestrictions: [], // TODO: Get from user preferences
            preferredCuisine: "Any" // TODO: Get from user preferences
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        guard !data.isEmpty else {
            throw APIError.noData
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let recipe = try decoder.decode(BackendRecipe.self, from: data)
            return recipe.toRecipe()
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - Helper Methods
    
    private func prepareImageData(_ image: UIImage) throws -> Data {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError.imageProcessingError
        }
        return imageData
    }
    
    private func createMultipartBody(imageData: Data) -> Data {
        var body = Data()
        let boundary = "Boundary"
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"fridge.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
}

// MARK: - API Response Models

private struct DetectionResponse: Codable {
    let ingredients: [String]
    let confidence: [Double]?
}

private struct RecipeRequest: Codable {
    let ingredients: [String]
    let mealCraving: String
    let dietaryRestrictions: [String]
    let preferredCuisine: String
}

private struct BackendRecipe: Codable {
    let title: String
    let description: String
    let prepTime: Int
    let cookTime: Int
    let servings: Int
    let difficulty: String
    let ingredients: [BackendIngredient]
    let instructions: [BackendInstruction]
    let tags: [String]
    let nutritionInfo: BackendNutritionInfo?
    
    func toRecipe() -> Recipe {
        return Recipe(
            title: title,
            description: description,
            prepTime: prepTime,
            cookTime: cookTime,
            servings: servings,
            difficulty: Recipe.Difficulty(rawValue: difficulty) ?? .easy,
            ingredients: ingredients.map { $0.toIngredient() },
            instructions: instructions.map { $0.toInstruction() },
            tags: tags,
            nutritionInfo: nutritionInfo?.toNutritionInfo()
        )
    }
}

private struct BackendIngredient: Codable {
    let name: String
    let amount: String
    let unit: String?
    let notes: String?
    
    func toIngredient() -> Ingredient {
        return Ingredient(name: name, amount: amount, unit: unit, notes: notes)
    }
}

private struct BackendInstruction: Codable {
    let step: Int
    let text: String
    let time: Int?
    let temperature: String?
    let tips: String?
    
    func toInstruction() -> Instruction {
        return Instruction(step: step, text: text, time: time, temperature: temperature, tips: tips)
    }
}

private struct BackendNutritionInfo: Codable {
    let calories: Int?
    let protein: String?
    let carbs: String?
    let fat: String?
    let fiber: String?
    let sugar: String?
    let sodium: String?
    
    func toNutritionInfo() -> NutritionInfo {
        return NutritionInfo(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium
        )
    }
}