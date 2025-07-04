//
//  EnhancedMuscleGroupPicker.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import SwiftUI

struct EnhancedMuscleGroupPicker: View {
    @Binding var selectedMuscleGroups: Set<MuscleGroup>
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var expandedCategories: Set<ExerciseCategory> = []
    @State private var showingAnatomyView = false
    
    private var groupedMuscleGroups: [(category: ExerciseCategory, muscles: [MuscleGroup])] {
        let grouped = Dictionary(grouping: MuscleGroup.allCases) { $0.category }
        return grouped
            .map { (category: $0.key, muscles: $0.value) }
            .sorted { $0.category.rawValue < $1.category.rawValue }
    }
    
    private var filteredGroups: [(category: ExerciseCategory, muscles: [MuscleGroup])] {
        if searchText.isEmpty {
            return groupedMuscleGroups
        } else {
            return groupedMuscleGroups.compactMap { group in
                let filteredMuscles = group.muscles.filter { muscle in
                    muscle.rawValue.localizedCaseInsensitiveContains(searchText)
                }
                return filteredMuscles.isEmpty ? nil : (group.category, filteredMuscles)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Selected count
                if !selectedMuscleGroups.isEmpty {
                    selectedCountBar
                }
                
                // Muscle groups list
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.medium) {
                        ForEach(filteredGroups, id: \.category) { group in
                            MuscleGroupSection(
                                category: group.category,
                                muscles: group.muscles,
                                selectedMuscles: $selectedMuscleGroups,
                                isExpanded: expandedCategories.contains(group.category),
                                onToggleExpand: {
                                    toggleCategory(group.category)
                                }
                            )
                        }
                    }
                    .padding()
                }
                
                // Bottom action bar
                bottomActionBar
            }
            .navigationTitle("Select Muscle Groups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                    .disabled(selectedMuscleGroups.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search muscle groups...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
    
    private var selectedCountBar: some View {
        HStack {
            Text("\(selectedMuscleGroups.count) muscle groups selected")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Button("Clear All") {
                withAnimation(Theme.Animation.fast) {
                    selectedMuscleGroups.removeAll()
                }
                HapticManager.shared.selection()
            }
            .font(.caption)
            .foregroundColor(Theme.Colors.error)
        }
        .padding(.horizontal)
        .padding(.vertical, Theme.Spacing.xSmall)
        .background(Theme.Colors.primary.opacity(0.1))
    }
    
    private var bottomActionBar: some View {
        HStack(spacing: Theme.Spacing.medium) {
            Button(action: {
                showingAnatomyView = true
            }) {
                Label("Anatomy Guide", systemImage: "figure.stand")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
            
            Button(action: selectCommonGroups) {
                Label("Common Groups", systemImage: "star")
                    .font(.subheadline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(
            Rectangle()
                .fill(Color(UIColor.systemBackground))
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -2)
        )
    }
    
    // MARK: - Helper Methods
    
    private func toggleCategory(_ category: ExerciseCategory) {
        withAnimation(Theme.Animation.fast) {
            if expandedCategories.contains(category) {
                expandedCategories.remove(category)
            } else {
                expandedCategories.insert(category)
            }
        }
    }
    
    private func selectCommonGroups() {
        let commonGroups: Set<MuscleGroup> = [
            .pectoralMajor,
            .latissimusDorsi,
            .anteriorDeltoid,
            .bicepsBrachii,
            .tricepsBrachii,
            .quadriceps,
            .hamstrings,
            .rectusAbdominis
        ]
        
        withAnimation(Theme.Animation.fast) {
            selectedMuscleGroups = selectedMuscleGroups.union(commonGroups)
        }
        
        HapticManager.shared.impact(.medium)
    }
}

// MARK: - Muscle Group Section

struct MuscleGroupSection: View {
    let category: ExerciseCategory
    let muscles: [MuscleGroup]
    @Binding var selectedMuscles: Set<MuscleGroup>
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    
    private var selectedCount: Int {
        muscles.filter { selectedMuscles.contains($0) }.count
    }
    
    private var isAllSelected: Bool {
        muscles.allSatisfy { selectedMuscles.contains($0) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Section header
            Button(action: onToggleExpand) {
                HStack {
                    HStack(spacing: Theme.Spacing.small) {
                        Image(systemName: category.systemImage)
                            .font(.title3)
                            .foregroundColor(category.color)
                            .frame(width: 30)
                        
                        Text(category.rawValue)
                            .font(.headline)
                        
                        if selectedCount > 0 {
                            Text("(\(selectedCount))")
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: Theme.Spacing.small) {
                        if !isExpanded && selectedCount > 0 {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: Theme.Spacing.xSmall) {
                            ForEach(muscles.filter { selectedMuscles.contains($0) }.prefix(3), id: \.self) { muscle in
                                Text(muscle.rawValue)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(category.color.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                            
                            if selectedCount > 3 {
                                Text("+\(selectedCount - 3)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Muscle list
            if isExpanded {
                VStack(spacing: 0) {
                    // Select all button
                    Button(action: toggleAll) {
                        HStack {
                            Image(systemName: isAllSelected ? "checkmark.square.fill" : "square")
                                .foregroundColor(isAllSelected ? Theme.Colors.primary : .secondary)
                            
                            Text("Select All")
                                .font(.subheadline)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, Theme.Spacing.xSmall)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Individual muscles
                    ForEach(muscles, id: \.self) { muscle in
                        MuscleGroupRow(
                            muscle: muscle,
                            isSelected: selectedMuscles.contains(muscle),
                            category: category
                        ) {
                            toggleMuscle(muscle)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    private func toggleAll() {
        withAnimation(Theme.Animation.fast) {
            if isAllSelected {
                muscles.forEach { selectedMuscles.remove($0) }
            } else {
                muscles.forEach { selectedMuscles.insert($0) }
            }
        }
        HapticManager.shared.selection()
    }
    
    private func toggleMuscle(_ muscle: MuscleGroup) {
        withAnimation(Theme.Animation.fast) {
            if selectedMuscles.contains(muscle) {
                selectedMuscles.remove(muscle)
            } else {
                selectedMuscles.insert(muscle)
            }
        }
        HapticManager.shared.selection()
    }
}

// MARK: - Muscle Group Row

struct MuscleGroupRow: View {
    let muscle: MuscleGroup
    let isSelected: Bool
    let category: ExerciseCategory
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(muscle.rawValue)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .medium : .regular)
                        .foregroundColor(.primary)
                    
                    // Add description if needed
                    if let description = muscle.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(category.color)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, Theme.Spacing.small)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Muscle Group Extensions

extension MuscleGroup {
    var description: String? {
        switch self {
        case .pectoralMajor: return "Main chest muscle"
        case .pectoralMinor: return "Small chest muscle under pec major"
        case .latissimusDorsi: return "Large back muscle (lats)"
        case .trapezius: return "Upper back and neck"
        case .rhomboids: return "Between shoulder blades"
        case .erectorSpinae: return "Lower back muscles"
        case .anteriorDeltoid: return "Front shoulder"
        case .medialDeltoid: return "Side shoulder"
        case .posteriorDeltoid: return "Rear shoulder"
        case .bicepsBrachii: return "Front upper arm"
        case .tricepsBrachii: return "Back upper arm"
        case .forearms: return "Lower arm muscles"
        case .quadriceps: return "Front thigh"
        case .hamstrings: return "Back thigh"
        case .glutes: return "Buttocks muscles"
        case .calves: return "Lower leg muscles"
        case .hipFlexors: return "Front hip muscles"
        case .adductors: return "Inner thigh"
        case .abductors: return "Outer hip"
        case .rectusAbdominis: return "Six-pack muscles"
        case .obliques: return "Side abs"
        case .transverseAbdominis: return "Deep core"
        }
    }
}
