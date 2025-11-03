import SwiftUI
import UIKit
import PhotosUI

struct CameraView: View {
    @Binding var capturedImage: UIImage?
    @Binding var detectedIngredients: [String]
    @Binding var generatedRecipe: Recipe?
    @Binding var isLoading: Bool
    
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var inputSource: InputSource = .camera
    @State private var mealCraving = ""
    @State private var apiClient = APIClient()
    @State private var localInferenceService = LocalInferenceService()
    @State private var localLLMGenerator = LocalLLMRecipeGenerator()
    @State private var mlxGenerator: MLXRecipeGenerator?
    @AppStorage("useLocalProcessing") private var useLocalProcessing = true
    @AppStorage("useMLXGeneration") private var useMLXGeneration = false
    @State private var errorMessage: String?
    @State private var showRecipeDetail = false

    enum InputSource {
        case camera
        case photoLibrary
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {  // 減少從 20 到 12

                    if let image = capturedImage {
                        ImageDisplayView(
                            image: image,
                            detectedIngredients: detectedIngredients,
                            onRetake: {
                                capturedImage = nil
                                detectedIngredients = []
                                generatedRecipe = nil
                                errorMessage = nil
                            }
                        )
                    } else {
                        ImageInputView(
                            showCamera: $showCamera,
                            showImagePicker: $showImagePicker,
                            inputSource: $inputSource
                        )
                    }

                    if capturedImage != nil {
                        MealCravingInput(mealCraving: $mealCraving)

                        if detectedIngredients.isEmpty && !isLoading {
                            ProcessImageButton(
                                action: { Task { await processImage() } },
                                isEnabled: true
                            )
                        } else if !detectedIngredients.isEmpty {
                            GenerateRecipeButton(
                                action: { Task { await generateRecipe() } },
                                isEnabled: !mealCraving.isEmpty,
                                isLoading: isLoading
                            )
                        }
                    }

                    if isLoading {
                        LoadingView()
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.vertical, 8)
                    }

                    // Display generated recipe
                    if let recipe = generatedRecipe {
                        RecipeCard(recipe: recipe) {
                            showRecipeDetail = true
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .padding(.bottom, 30)  // 更多底部空間，避免被 tab bar 擋住
            }
            .navigationTitle("Scan Fridge")
        }
        .sheet(isPresented: $showRecipeDetail) {
            if let recipe = generatedRecipe {
                RecipeDetailView(recipe: recipe)
            }
        }
        .sheet(isPresented: $showCamera) {
            ImagePickerView(
                sourceType: .camera,
                selectedImage: $capturedImage
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(
                sourceType: .photoLibrary,
                selectedImage: $capturedImage
            )
        }
    }
    
    private func processImage() {
        guard let image = capturedImage else { return }
        
        errorMessage = nil
        isLoading = true

        Task {
            do {
                let ingredients: [String]

                if useLocalProcessing {
                    // Use local inference
                    print("🔧 Using local processing")
                    ingredients = try await localInferenceService.detect(image: image)
                } else {
                    // Use server-side API
                    print("🌐 Using server processing")
                    ingredients = try await apiClient.detectIngredients(in: image)
                }

                await MainActor.run {
                    self.detectedIngredients = ingredients
                    self.isLoading = false
                }
            } catch {
                let errorDescription = error.localizedDescription
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Detection Failed: \(errorDescription)"
                }
                print("Error detecting ingredients: \(error)")
            }
        }
    }
    
    private func generateRecipe() {
        guard !detectedIngredients.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        // 防止 MLX 推理時自動鎖屏（避免後台 GPU 錯誤）
        let wasIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
        if useMLXGeneration {
            UIApplication.shared.isIdleTimerDisabled = true
            print("🔒 已禁用自動鎖屏（MLX 需要保持前台運行）")
        }

        Task {
            do {
                let recipe: Recipe

                if useLocalProcessing {
                    // 使用本地 LLM 生成食譜
                    if useMLXGeneration {
                        // 使用 MLX on-device 生成
                        print("🤖 Using MLX on-device LLM for recipe generation")
                        if #available(iOS 16.0, *) {
                            if mlxGenerator == nil {
                                mlxGenerator = MLXRecipeGenerator()
                            }
                            recipe = try await mlxGenerator!.generateRecipe(
                                ingredients: detectedIngredients,
                                mealCraving: mealCraving
                            )
                        } else {
                            print("⚠️ MLX not available on this iOS version, using Ollama")
                            recipe = try await localLLMGenerator.generateRecipe(
                                ingredients: detectedIngredients,
                                mealCraving: mealCraving
                            )
                        }
                    } else {
                        // 使用 Ollama 本地 API
                        print("🔧 Using local Ollama API for recipe generation")
                        recipe = try await localLLMGenerator.generateRecipe(
                            ingredients: detectedIngredients,
                            mealCraving: mealCraving
                        )
                    }
                } else {
                    // Cloud Server Mode: Detection via AWS, Generation via MLX on-device
                    // (Docker backend only provides detection service, recipe generation uses on-device MLX)
                    print("🌐🤖 Cloud mode: Using MLX on-device for recipe generation")
                    if #available(iOS 16.0, *) {
                        if mlxGenerator == nil {
                            mlxGenerator = MLXRecipeGenerator()
                        }
                        recipe = try await mlxGenerator!.generateRecipe(
                            ingredients: detectedIngredients,
                            mealCraving: mealCraving
                        )
                    } else {
                        throw NSError(
                            domain: "MLXError",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Cloud mode requires iOS 16.0+ for on-device recipe generation"]
                        )
                    }
                }

                await MainActor.run {
                    self.generatedRecipe = recipe
                    self.isLoading = false
                    // 恢復原本的自動鎖屏設定
                    UIApplication.shared.isIdleTimerDisabled = wasIdleTimerDisabled
                    print("🔓 已恢復自動鎖屏設定")
                }
            } catch {
                let errorDescription = error.localizedDescription
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Recipe generation failed: \(errorDescription)"
                    // 即使出錯也要恢復設定
                    UIApplication.shared.isIdleTimerDisabled = wasIdleTimerDisabled
                    print("🔓 已恢復自動鎖屏設定")
                }
                print("Error generating recipe: \(error)")
            }
        }
    }
}

struct ImageInputView: View {
    @Binding var showCamera: Bool
    @Binding var showImagePicker: Bool
    @Binding var inputSource: CameraView.InputSource
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Capture Your Fridge")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Take a photo of your fridge interior or select from your photo library")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                Button(action: {
                    inputSource = .camera
                    showCamera = true
                }) {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("Camera")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    inputSource = .photoLibrary
                    showImagePicker = true
                }) {
                    VStack {
                        Image(systemName: "photo.fill")
                            .font(.title2)
                        Text("Photos")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}

struct ImageDisplayView: View {
    let image: UIImage
    let detectedIngredients: [String]
    let onRetake: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)  // 減少從 300 到 200
                .cornerRadius(12)
                .shadow(radius: 3)

            if !detectedIngredients.isEmpty {
                IngredientsList(ingredients: detectedIngredients)
            }

            Button("Retake Photo", action: onRetake)
                .font(.subheadline)
                .foregroundColor(.orange)
        }
    }
}

struct IngredientsList: View {
    let ingredients: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Detected Ingredients:")
                .font(.subheadline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 6) {
                ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 10))
                        Text(ingredient)
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MealCravingInput: View {
    @Binding var mealCraving: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("What are you craving?")
                .font(.subheadline)
                .fontWeight(.semibold)

            TextField("e.g., pasta, stir-fry, salad", text: $mealCraving)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProcessImageButton: View {
    let action: () async -> Void
    let isEnabled: Bool

    var body: some View {
        Button(action: { Task { await action() } }) {
            Text("Process Image")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isEnabled ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled(!isEnabled)
    }
}

struct GenerateRecipeButton: View {
    let action: () async -> Void
    let isEnabled: Bool
    let isLoading: Bool

    var body: some View {
        Button(action: { Task { await action() } }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(isLoading ? "Generating..." : "Generate Recipe")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isEnabled && !isLoading ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(!isEnabled || isLoading)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)

            Text("Processing...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct RecipeCard: View {
    let recipe: Recipe
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)

                Text("Recipe Generated!")
                    .font(.headline)
                    .foregroundColor(.green)

                Spacer()
            }

            Text(recipe.title)
                .font(.title2)
                .fontWeight(.bold)

            Text(recipe.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack(spacing: 15) {
                Label("\(recipe.prepTime + recipe.cookTime) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Label("\(recipe.servings) servings", systemImage: "person.2")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(recipe.difficulty.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(difficultyColor.opacity(0.2))
                    .foregroundColor(difficultyColor)
                    .cornerRadius(6)
            }

            Button(action: action) {
                HStack {
                    Text("View Full Recipe")
                        .font(.headline)

                    Spacer()

                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .shadow(radius: 3)
    }

    var difficultyColor: Color {
        switch recipe.difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

#Preview {
    CameraView(
        capturedImage: .constant(nil),
        detectedIngredients: .constant([]),
        generatedRecipe: .constant(nil),
        isLoading: .constant(false)
    )
}
