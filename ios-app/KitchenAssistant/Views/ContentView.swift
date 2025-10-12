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
            VStack(spacing: 30) {
                Image(systemName: "refrigerator.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
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
                
                Spacer()
            }
            .padding()
            .navigationTitle("Kitchen Assistant")
        }
    }
}

struct SettingsView: View {
    @AppStorage("useLocalProcessing") private var useLocalProcessing = true
    @State private var dietaryRestrictions = ""
    @State private var preferredCuisine = "Any"
    
    let cuisineOptions = ["Any", "Italian", "Asian", "Mexican", "Mediterranean", "American"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Processing") {
                    Toggle("Use Local AI Processing", isOn: $useLocalProcessing)
                    Text("When enabled, all processing happens on your device for maximum privacy")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                        Text("YOLO + LLaMA")
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
            Group {
                if let recipe = recipe {
                    ScrollView {
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)

                            Text("Your Recipe is Ready!")
                                .font(.title2)
                                .fontWeight(.bold)

                            RecipePreviewCard(recipe: recipe) {
                                showRecipeDetail = true
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)

                        Text("No Recipe Yet")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Generate a recipe by scanning your fridge in the 'Scan Fridge' tab")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        Spacer()
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
        VStack(alignment: .leading, spacing: 15) {
            Text(recipe.title)
                .font(.title)
                .fontWeight(.bold)

            Text(recipe.description)
                .font(.body)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                Label("\(recipe.prepTime + recipe.cookTime) min", systemImage: "clock.fill")
                    .font(.subheadline)

                Label("\(recipe.servings) servings", systemImage: "person.2.fill")
                    .font(.subheadline)

                Spacer()
            }
            .foregroundColor(.green)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Ingredients (\(recipe.ingredients.count))")
                    .font(.headline)

                ForEach(recipe.ingredients.prefix(3)) { ingredient in
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.green)

                        Text(ingredient.displayText)
                            .font(.subheadline)
                    }
                }

                if recipe.ingredients.count > 3 {
                    Text("+ \(recipe.ingredients.count - 3) more...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Button(action: action) {
                Text("View Full Recipe")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .shadow(radius: 5)
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