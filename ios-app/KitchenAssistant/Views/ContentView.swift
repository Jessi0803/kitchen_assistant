import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var capturedImage: UIImage?
    @State private var detectedIngredients: [String] = []
    @State private var generatedRecipe: Recipe?
    @State private var isLoading = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            CameraView(
                capturedImage: $capturedImage,
                detectedIngredients: $detectedIngredients,
                generatedRecipe: $generatedRecipe,
                isLoading: $isLoading
            )
            .tabItem {
                Image(systemName: "camera.fill")
                Text("Scan Fridge")
            }
            .tag(1)
            
            RecipeTab(recipe: generatedRecipe)
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Recipe")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.green)
    }
}

struct HomeView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    Image(systemName: "refrigerator.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                        .padding(.top, 20)

                    Text("Edge-AI Kitchen Assistant")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Take a photo of your fridge and get instant recipe suggestions!")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Scan your fridge")
                        }
                        HStack {
                            Image(systemName: "eye")
                            Text("AI detects ingredients")
                        }
                        HStack {
                            Image(systemName: "book")
                            Text("Get personalized recipes")
                        }
                        HStack {
                            Image(systemName: "lock.shield")
                            Text("100% private & offline")
                        }
                    }
                    .foregroundColor(.green)

                    Spacer(minLength: 40)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Kitchen Assistant")
        }
    }
}

struct SettingsView: View {
    @AppStorage("useLocalProcessing") private var useLocalProcessing = true
    @AppStorage("useMLXGeneration") private var useMLXGeneration = false
    @State private var dietaryRestrictions = ""
    @State private var preferredCuisine = "Any"
    
    let cuisineOptions = ["Any", "Italian", "Asian", "Mexican", "Mediterranean", "American"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("AI Processing Mode")) {
                    Toggle("Use Local AI Processing", isOn: $useLocalProcessing)
                    
                    if useLocalProcessing {
                        Toggle("Use On-Device MLX LLM", isOn: $useMLXGeneration)
                            .disabled(!useLocalProcessing)
                        
                        if useMLXGeneration {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("🤖 MLX On-Device Mode")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                                Text("• 100% offline, model runs on your device")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("• Slower but completely private")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("• Requires iPhone 12+ or M1+ Mac")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("🔧 Ollama API Mode")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                                Text("• Connects to local Ollama service")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("• Faster generation (localhost:11434)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("• Requires Ollama running on Mac")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("🌐 Cloud Server Mode")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            Text("• Connects to remote API server")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("• Requires internet connection")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("• Works on any device")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Dietary Preferences") {
                    TextField("Dietary Restrictions", text: $dietaryRestrictions)
                        .placeholder(when: dietaryRestrictions.isEmpty) {
                            Text("e.g., vegetarian, gluten-free, dairy-free")
                        }
                    
                    Picker("Preferred Cuisine", selection: $preferredCuisine) {
                        ForEach(cuisineOptions, id: \.self) { cuisine in
                            Text(cuisine).tag(cuisine)
                        }
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("AI Models")
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("YOLOv8n (CoreML)")
                                .foregroundColor(.secondary)
                            Text("Qwen2.5-0.5B (MLX)")
                                .foregroundColor(.secondary)
                                .font(.caption2)
                        }
                    }
                    
                    HStack {
                        Text("Model Size")
                        Spacer()
                        Text("~290MB")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct RecipeTab: View {
    let recipe: Recipe?
    @State private var showRecipeDetail = false

    var body: some View {
        NavigationView {
            ScrollView {
                if let recipe = recipe {
                    VStack(spacing: 15) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                            .padding(.top, 15)

                        Text("Your Recipe is Ready!")
                            .font(.title3)
                            .fontWeight(.bold)

                        RecipePreviewCard(recipe: recipe) {
                            showRecipeDetail = true
                        }
                        .padding(.horizontal)

                        // 底部留白
                        Color.clear.frame(height: 60)
                    }
                    .padding(.vertical, 12)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 70))
                            .foregroundColor(.secondary)
                            .padding(.top, 40)

                        Text("No Recipe Yet")
                            .font(.title3)
                            .fontWeight(.bold)

                        Text("Generate a recipe by scanning your fridge in the 'Scan Fridge' tab")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Recipe")
        }
        .sheet(isPresented: $showRecipeDetail) {
            if let recipe = recipe {
                RecipeDetailView(recipe: recipe)
            }
        }
    }
}

struct RecipePreviewCard: View {
    let recipe: Recipe
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(recipe.title)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(2)

            Text(recipe.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack(spacing: 15) {
                Label("\(recipe.prepTime + recipe.cookTime) min", systemImage: "clock.fill")
                    .font(.caption)

                Label("\(recipe.servings) servings", systemImage: "person.2.fill")
                    .font(.caption)

                Spacer()
            }
            .foregroundColor(.green)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Ingredients (\(recipe.ingredients.count))")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                ForEach(recipe.ingredients.prefix(3)) { ingredient in
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 5))
                            .foregroundColor(.green)

                        Text(ingredient.displayText)
                            .font(.caption)
                    }
                }

                if recipe.ingredients.count > 3 {
                    Text("+ \(recipe.ingredients.count - 3) more...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Button(action: action) {
                Text("View Full Recipe")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 3)
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    ContentView()
}