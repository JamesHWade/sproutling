//
//  GardenComponents.swift
//  Sproutling
//
//  Garden-themed UI components for mastery visualization
//

import SwiftUI

// MARK: - Plant View

/// Displays a single plant at its current growth stage
/// Animates transitions between stages for satisfying growth moments
struct PlantView: View {
    let stage: GrowthStage
    var size: CGFloat = 40
    var showLabel: Bool = false
    var label: String?
    var animated: Bool = true

    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Glow effect for bloomed plants
                if stage == .bloomed {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.pink.opacity(0.3), .clear],
                                center: .center,
                                startRadius: size * 0.2,
                                endRadius: size * 0.6
                            )
                        )
                        .frame(width: size * 1.2, height: size * 1.2)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }

                // Pulse effect for wilting plants
                if stage == .wilting {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: size * 1.1, height: size * 1.1)
                        .scaleEffect(isAnimating ? 1.15 : 1.0)
                }

                // Plant emoji
                Text(stage.emoji)
                    .font(.system(size: size * 0.8))
                    .scaleEffect(isAnimating && stage == .bloomed ? 1.05 : 1.0)
            }
            .frame(width: size, height: size)

            // Optional label below
            if showLabel, let label = label {
                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .onAppear {
            if animated && !reduceMotion {
                startAnimation()
            }
        }
    }

    private var accessibilityDescription: String {
        var desc = "\(stage.displayName) plant"
        if let label = label {
            desc = "\(label): \(desc)"
        }
        if stage.needsAttention {
            desc += ", needs attention"
        }
        return desc
    }

    private func startAnimation() {
        guard stage == .bloomed || stage == .wilting else { return }

        withAnimation(
            .easeInOut(duration: stage == .wilting ? 1.5 : 2.0)
            .repeatForever(autoreverses: true)
        ) {
            isAnimating = true
        }
    }
}

// MARK: - Plant Growth Animation View

/// Shows animated transition between growth stages
/// Used when a plant levels up after successful practice
struct PlantGrowthAnimation: View {
    let fromStage: GrowthStage
    let toStage: GrowthStage
    var onComplete: (() -> Void)?

    @State private var currentStage: GrowthStage
    @State private var scale: CGFloat = 1.0
    @State private var showSparkles = false

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    init(fromStage: GrowthStage, toStage: GrowthStage, onComplete: (() -> Void)? = nil) {
        self.fromStage = fromStage
        self.toStage = toStage
        self.onComplete = onComplete
        self._currentStage = State(initialValue: fromStage)
    }

    var body: some View {
        ZStack {
            // Sparkle particles
            if showSparkles {
                ForEach(0..<8, id: \.self) { index in
                    SparkleParticle(index: index)
                }
            }

            // The plant
            Text(currentStage.emoji)
                .font(.system(size: 80))
                .scaleEffect(scale)
        }
        .onAppear {
            if reduceMotion {
                currentStage = toStage
                onComplete?()
            } else {
                animateGrowth()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Plant growing from \(fromStage.displayName) to \(toStage.displayName)")
    }

    private func animateGrowth() {
        // Phase 1: Shrink slightly (anticipation)
        withAnimation(.easeInOut(duration: 0.2)) {
            scale = 0.8
        }

        // Phase 2: Grow and change
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showSparkles = true
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.2
                currentStage = toStage
            }
        }

        // Phase 3: Settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeOut(duration: 0.3)) {
                scale = 1.0
            }
        }

        // Complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onComplete?()
        }
    }
}

// MARK: - Sparkle Particle

private struct SparkleParticle: View {
    let index: Int

    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Text("✨")
            .font(.system(size: 20))
            .offset(offset)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                let angle = Double(index) * (.pi / 4)
                let distance: CGFloat = 60

                withAnimation(.easeOut(duration: 0.5).delay(Double(index) * 0.05)) {
                    offset = CGSize(
                        width: cos(angle) * distance,
                        height: sin(angle) * distance
                    )
                    opacity = 1.0
                    scale = 1.0
                }

                withAnimation(.easeIn(duration: 0.3).delay(0.5)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Garden Grid View

/// Displays a grid of plants showing mastery across items
/// Used in progress screens and subject overviews
struct GardenGridView: View {
    let items: [GardenItem]
    var columns: Int = 5
    var plantSize: CGFloat = 44
    var showLabels: Bool = true
    var onItemTap: ((GardenItem) -> Void)?

    var body: some View {
        let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)

        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(items) { item in
                Button {
                    onItemTap?(item)
                } label: {
                    PlantView(
                        stage: item.stage,
                        size: plantSize,
                        showLabel: showLabels,
                        label: item.label
                    )
                }
                .buttonStyle(.plain)
                .disabled(onItemTap == nil)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Garden grid with \(items.count) plants")
    }
}

/// Model for a single item in the garden grid
struct GardenItem: Identifiable {
    let id: String
    let label: String
    let stage: GrowthStage
    let itemId: String?

    init(id: String = UUID().uuidString, label: String, stage: GrowthStage, itemId: String? = nil) {
        self.id = id
        self.label = label
        self.stage = stage
        self.itemId = itemId
    }
}

// MARK: - Garden Summary View

/// Shows a compact summary of garden health
/// "7 blooming · 2 growing · 11 new"
struct GardenSummaryView: View {
    let items: [GardenItem]

    private var stageCounts: [(GrowthStage, Int)] {
        var counts: [GrowthStage: Int] = [:]
        for item in items {
            counts[item.stage, default: 0] += 1
        }
        return GrowthStage.allCases
            .map { ($0, counts[$0] ?? 0) }
            .filter { $0.1 > 0 }
    }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(stageCounts, id: \.0) { stage, count in
                HStack(spacing: 4) {
                    Text(stage.emoji)
                        .font(.subheadline)
                    Text("\(count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        stageCounts
            .map { "\($0.1) \($0.0.displayName.lowercased())" }
            .joined(separator: ", ")
    }
}

// MARK: - Mastery Meter View

/// Progress bar showing mastery percentage for a level or subject
struct MasteryMeterView: View {
    let progress: Double  // 0.0 to 1.0
    var color: Color = .green
    var showPercentage: Bool = true
    var height: CGFloat = 16

    var body: some View {
        HStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.gray.opacity(0.2))

                    // Progress fill with gradient
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.8), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geometry.size.width * min(1, progress)))
                        .animation(.spring(response: 0.5), value: progress)

                    // Shine effect
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .frame(width: max(0, geometry.size.width * min(1, progress)))
                        .frame(height: height / 2)
                        .offset(y: -height / 4)
                }
            }
            .frame(height: height)

            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
                    .frame(width: 44, alignment: .trailing)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mastery progress: \(Int(progress * 100)) percent")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }
}

// MARK: - Needs Water Alert

/// Alert badge showing plants that need review
struct NeedsWaterAlert: View {
    let count: Int
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 8) {
                Text("🥀")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(count) plant\(count == 1 ? "" : "s") need\(count == 1 ? "s" : "") water!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)

                    if onTap != nil {
                        Text("Tap to review")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) plants need watering")
        .accessibilityHint(onTap != nil ? Text("Double tap to review") : Text(""))
    }
}

// MARK: - Previews

#Preview("Plant Stages") {
    VStack(spacing: 20) {
        Text("Growth Stages")
            .font(.headline)

        HStack(spacing: 20) {
            ForEach(GrowthStage.allCases, id: \.self) { stage in
                VStack {
                    PlantView(stage: stage, size: 50)
                    Text(stage.displayName)
                        .font(.caption)
                }
            }
        }
    }
    .padding()
}

#Preview("Garden Grid") {
    let sampleItems = [
        GardenItem(label: "1", stage: .bloomed),
        GardenItem(label: "2", stage: .bloomed),
        GardenItem(label: "3", stage: .budding),
        GardenItem(label: "4", stage: .growing),
        GardenItem(label: "5", stage: .growing),
        GardenItem(label: "6", stage: .planted),
        GardenItem(label: "7", stage: .planted),
        GardenItem(label: "8", stage: .seed),
        GardenItem(label: "9", stage: .seed),
        GardenItem(label: "10", stage: .seed)
    ]

    VStack(spacing: 20) {
        Text("Number Garden")
            .font(.headline)

        GardenGridView(items: sampleItems)
            .padding()

        GardenSummaryView(items: sampleItems)
    }
    .padding()
}

#Preview("Mastery Meter") {
    VStack(spacing: 20) {
        MasteryMeterView(progress: 0.85, color: .green)
        MasteryMeterView(progress: 0.45, color: .blue)
        MasteryMeterView(progress: 0.1, color: .pink)
    }
    .padding()
}

#Preview("Growth Animation") {
    PlantGrowthAnimation(fromStage: .growing, toStage: .budding)
}

#Preview("Needs Water Alert") {
    VStack(spacing: 20) {
        NeedsWaterAlert(count: 3) {
            print("Review tapped")
        }

        NeedsWaterAlert(count: 1)
    }
    .padding()
}
