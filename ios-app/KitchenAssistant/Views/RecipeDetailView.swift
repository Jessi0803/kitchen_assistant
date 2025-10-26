import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recipe.title)
                                .font(.system(size: 24, weight: .bold))

                            Text(recipe.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            // Recipe metadata
                            HStack(spacing: 15) {
                                MetadataItem(icon: "clock", text: "\(recipe.prepTime + recipe.cookTime) min")
                                MetadataItem(icon: "person.2", text: "\(recipe.servings) servings")
                                DifficultyBadge(difficulty: recipe.difficulty)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.horizontal)

                    Divider()

                    // Ingredients Section
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Ingredients", icon: "list.bullet")

                        ForEach(recipe.ingredients) { ingredient in
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 10))
                                    .padding(.top, 3)

                                Text(ingredient.displayText)
                                    .font(.caption)

                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    // Instructions Section
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Instructions", icon: "list.number")

                        ForEach(recipe.instructions) { instruction in
                            InstructionRow(instruction: instruction)
                        }
                    }
                    .padding(.horizontal)

                    // Nutrition Info (if available)
                    if let nutrition = recipe.nutritionInfo {
                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Nutrition Info", icon: "heart.circle")

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
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

                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Tags", icon: "tag")

                            FlowLayout(spacing: 6) {
                                ForEach(recipe.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundColor(.green)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // 重要：底部留白，避免被遮住 - 增加到 100px
                    Color.clear.frame(height: 100)
                }
                .padding(.vertical, 12)
            }

            // 滾動提示指示器
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(8)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                    Spacer()
                }
                .padding(.bottom, 10)
            }
            .allowsHitTesting(false)  // 不阻擋點擊事件
        }  // <- ZStack 結束
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        }  // <- NavigationView 結束
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
        HStack(alignment: .top, spacing: 10) {
            // Step number
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 26, height: 26)

                Text("\(instruction.step)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(instruction.text)
                    .font(.caption)

                HStack(spacing: 10) {
                    if let time = instruction.time {
                        Label("\(time) min", systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if let temp = instruction.temperature {
                        Label(temp, systemImage: "thermometer")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                if let tips = instruction.tips {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text(tips)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    .padding(.top, 1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct NutritionItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
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
