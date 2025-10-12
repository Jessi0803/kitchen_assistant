import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text(recipe.title)
                            .font(.system(size: 28, weight: .bold))

                        Text(recipe.description)
                            .font(.body)
                            .foregroundColor(.secondary)

                        // Recipe metadata
                        HStack(spacing: 20) {
                            MetadataItem(icon: "clock", text: "\(recipe.prepTime + recipe.cookTime) min")
                            MetadataItem(icon: "person.2", text: "\(recipe.servings) servings")
                            DifficultyBadge(difficulty: recipe.difficulty)
                        }
                        .padding(.top, 5)
                    }
                    .padding(.horizontal)

                    Divider()

                    // Ingredients Section
                    VStack(alignment: .leading, spacing: 15) {
                        SectionHeader(title: "Ingredients", icon: "list.bullet")

                        ForEach(recipe.ingredients) { ingredient in
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 12))
                                    .padding(.top, 4)

                                Text(ingredient.displayText)
                                    .font(.body)

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    // Instructions Section
                    VStack(alignment: .leading, spacing: 15) {
                        SectionHeader(title: "Instructions", icon: "list.number")

                        ForEach(recipe.instructions) { instruction in
                            InstructionRow(instruction: instruction)
                        }
                    }
                    .padding(.horizontal)

                    // Nutrition Info (if available)
                    if let nutrition = recipe.nutritionInfo {
                        Divider()

                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "Nutrition Info", icon: "heart.circle")

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                if let calories = nutrition.calories {
                                    NutritionItem(label: "Calories", value: "\(calories)")
                                }
                                if let protein = nutrition.protein {
                                    NutritionItem(label: "Protein", value: protein)
                                }
                                if let carbs = nutrition.carbs {
                                    NutritionItem(label: "Carbs", value: carbs)
                                }
                                if let fat = nutrition.fat {
                                    NutritionItem(label: "Fat", value: fat)
                                }
                                if let fiber = nutrition.fiber {
                                    NutritionItem(label: "Fiber", value: fiber)
                                }
                                if let sugar = nutrition.sugar {
                                    NutritionItem(label: "Sugar", value: sugar)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Tags
                    if !recipe.tags.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Tags", icon: "tag")

                            FlowLayout(spacing: 8) {
                                ForEach(recipe.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundColor(.green)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
        }
    }
}

struct MetadataItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .foregroundColor(.secondary)
    }
}

struct DifficultyBadge: View {
    let difficulty: Recipe.Difficulty

    var badgeColor: Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }

    var body: some View {
        Text(difficulty.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.2))
            .foregroundColor(badgeColor)
            .cornerRadius(8)
    }
}

struct InstructionRow: View {
    let instruction: Instruction

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 32, height: 32)

                Text("\(instruction.step)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(instruction.text)
                    .font(.body)

                HStack(spacing: 12) {
                    if let time = instruction.time {
                        Label("\(time) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let temp = instruction.temperature {
                        Label(temp, systemImage: "thermometer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let tips = instruction.tips {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(tips)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct NutritionItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// Simple Flow Layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                     y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    RecipeDetailView(recipe: Recipe.sample)
}
