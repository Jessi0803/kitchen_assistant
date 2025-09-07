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
            
            RecipeView(recipe: generatedRecipe)
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
    @State private var useLocalProcessing = true
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