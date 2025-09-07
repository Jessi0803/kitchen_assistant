import SwiftUI

struct RecipeView: View {
    let recipe: Recipe?
    
    var body: some View {
        NavigationView {
            if let recipe = recipe {
                RecipeDetailView(recipe: recipe)
            } else {
                RecipeEmptyState()
            }
        }
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                RecipeHeaderView(recipe: recipe)
                
                RecipeMetadataView(recipe: recipe)
                
                Picker("Recipe Sections", selection: $selectedTab) {
                    Text("Ingredients").tag(0)
                    Text("Instructions").tag(1)
                    if recipe.nutritionInfo != nil {
                        Text("Nutrition").tag(2)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                Group {
                    switch selectedTab {
                    case 0:
                        IngredientsTabView(ingredients: recipe.ingredients)
                    case 1:
                        InstructionsTabView(instructions: recipe.instructions)
                    case 2:
                        if let nutrition = recipe.nutritionInfo {
                            NutritionTabView(nutrition: nutrition)
                        }
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 100)
            }
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct RecipeHeaderView: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(recipe.description)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(recipe.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
}

struct RecipeMetadataView: View {
    let recipe: Recipe
    
    var body: some View {
        HStack(spacing: 20) {
            MetadataItem(
                icon: "clock",
                title: "Prep",
                value: "\(recipe.prepTime)m"
            )
            
            MetadataItem(
                icon: "flame",
                title: "Cook",
                value: "\(recipe.cookTime)m"
            )
            
            MetadataItem(
                icon: "person.2",
                title: "Servings",
                value: "\(recipe.servings)"
            )
            
            MetadataItem(
                icon: "chart.bar",
                title: "Difficulty",
                value: recipe.difficulty.rawValue,
                color: recipe.difficulty.color
            )
        }
        .padding(.horizontal)
    }
}

struct MetadataItem: View {
    let icon: String
    let title: String
    let value: String
    let color: String?
    
    init(icon: String, title: String, value: String, color: String? = nil) {
        self.icon = icon
        self.title = title
        self.value = value
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(colorFromString(color) ?? .primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(colorFromString(color) ?? .primary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func colorFromString(_ colorString: String?) -> Color? {
        guard let colorString = colorString else { return nil }
        switch colorString.lowercased() {
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "blue": return .blue
        default: return nil
        }
    }
}

struct IngredientsTabView: View {
    let ingredients: [Ingredient]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.headline)
            
            ForEach(ingredients) { ingredient in
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text(ingredient.displayText)
                        .font(.body)
                    
                    Spacer()
                }
                .padding(.vertical, 2)
            }
        }
    }
}

struct InstructionsTabView: View {
    let instructions: [Instruction]
    @State private var completedSteps: Set<Int> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Instructions")
                .font(.headline)
            
            ForEach(instructions) { instruction in
                InstructionStepView(
                    instruction: instruction,
                    isCompleted: completedSteps.contains(instruction.step)
                ) {
                    if completedSteps.contains(instruction.step) {
                        completedSteps.remove(instruction.step)
                    } else {
                        completedSteps.insert(instruction.step)
                    }
                }
            }
        }
    }
}

struct InstructionStepView: View {
    let instruction: Instruction
    let isCompleted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Step \(instruction.step)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    if let time = instruction.time {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("\(time)m")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Text(instruction.text)
                    .font(.body)
                    .strikethrough(isCompleted)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                
                if let temperature = instruction.temperature {
                    HStack {
                        Image(systemName: "thermometer")
                            .font(.caption)
                        Text(temperature)
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                }
                
                if let tips = instruction.tips {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "lightbulb")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(tips)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct NutritionTabView: View {
    let nutrition: NutritionInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Information")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let calories = nutrition.calories {
                    NutritionItemView(label: "Calories", value: "\(calories)")
                }
                if let protein = nutrition.protein {
                    NutritionItemView(label: "Protein", value: protein)
                }
                if let carbs = nutrition.carbs {
                    NutritionItemView(label: "Carbs", value: carbs)
                }
                if let fat = nutrition.fat {
                    NutritionItemView(label: "Fat", value: fat)
                }
                if let fiber = nutrition.fiber {
                    NutritionItemView(label: "Fiber", value: fiber)
                }
                if let sugar = nutrition.sugar {
                    NutritionItemView(label: "Sugar", value: sugar)
                }
                if let sodium = nutrition.sodium {
                    NutritionItemView(label: "Sodium", value: sodium)
                }
            }
        }
    }
}

struct NutritionItemView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
}

struct RecipeEmptyState: View {
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Recipe Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Scan your fridge and generate a recipe to see it here!")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Recipe")
    }
}

#Preview {
    RecipeView(recipe: Recipe.sample)
}