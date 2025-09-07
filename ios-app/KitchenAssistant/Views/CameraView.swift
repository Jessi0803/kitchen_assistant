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
    
    enum InputSource {
        case camera
        case photoLibrary
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    if let image = capturedImage {
                        ImageDisplayView(
                            image: image,
                            detectedIngredients: detectedIngredients,
                            onRetake: {
                                capturedImage = nil
                                detectedIngredients = []
                                generatedRecipe = nil
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
                                action: processImage,
                                isEnabled: true
                            )
                        } else if !detectedIngredients.isEmpty {
                            GenerateRecipeButton(
                                action: generateRecipe,
                                isEnabled: !mealCraving.isEmpty,
                                isLoading: isLoading
                            )
                        }
                    }
                    
                    if isLoading {
                        LoadingView()
                    }
                }
                .padding()
            }
            .navigationTitle("Scan Fridge")
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
        
        isLoading = true
        
        Task {
            do {
                let ingredients = try await apiClient.detectIngredients(in: image)
                await MainActor.run {
                    self.detectedIngredients = ingredients
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("Error detecting ingredients: \(error)")
            }
        }
    }
    
    private func generateRecipe() {
        guard !detectedIngredients.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                let recipe = try await apiClient.generateRecipe(
                    ingredients: detectedIngredients,
                    mealCraving: mealCraving
                )
                await MainActor.run {
                    self.generatedRecipe = recipe
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
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
        VStack(spacing: 15) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 300)
                .cornerRadius(12)
                .shadow(radius: 5)
            
            if !detectedIngredients.isEmpty {
                IngredientsList(ingredients: detectedIngredients)
            }
            
            Button("Retake Photo", action: onRetake)
                .foregroundColor(.orange)
        }
    }
}

struct IngredientsList: View {
    let ingredients: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Detected Ingredients:")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(ingredients, id: \.self) { ingredient in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(ingredient)
                            .font(.body)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MealCravingInput: View {
    @Binding var mealCraving: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What are you craving?")
                .font(.headline)
            
            TextField("e.g., pasta, stir-fry, salad", text: $mealCraving)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProcessImageButton: View {
    let action: () -> Void
    let isEnabled: Bool
    
    var body: some View {
        Button(action: action) {
            Text("Process Image")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isEnabled ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled(!isEnabled)
    }
}

struct GenerateRecipeButton: View {
    let action: () -> Void
    let isEnabled: Bool
    let isLoading: Bool
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(isLoading ? "Generating Recipe..." : "Generate Recipe")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
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

#Preview {
    CameraView(
        capturedImage: .constant(nil),
        detectedIngredients: .constant([]),
        generatedRecipe: .constant(nil),
        isLoading: .constant(false)
    )
}