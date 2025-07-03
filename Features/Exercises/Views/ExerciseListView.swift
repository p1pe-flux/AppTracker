//
//  ExerciseListView.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import SwiftUI
import CoreData

struct ExerciseListView: View {
    @StateObject private var viewModel: ExerciseViewModel
    @State private var showingCreateExercise = false
    @State private var exerciseToEdit: Exercise?
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: ExerciseViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Category filter
                categoryFilter
                
                // Exercise list
                if viewModel.isLoading {
                    ProgressView("Loading exercises...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredExercises.isEmpty {
                    emptyState
                } else {
                    exerciseList
                }
            }
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateExercise = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateExercise) {
                ExerciseFormView(viewModel: viewModel)
            }
            .sheet(item: $exerciseToEdit) { exercise in
                ExerciseFormView(viewModel: viewModel, exercise: exercise)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.showError = false }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search exercises...", text: $viewModel.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All categories chip
                CategoryChip(
                    title: "All",
                    isSelected: viewModel.selectedCategory == nil,
                    action: { viewModel.selectCategory(nil) }
                )
                
                // Category chips
                ForEach(viewModel.categories, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        systemImage: category.systemImage,
                        isSelected: viewModel.selectedCategory == category,
                        action: { viewModel.selectCategory(category) }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private var exerciseList: some View {
        List {
            ForEach(viewModel.filteredExercises) { exercise in
                ExerciseRowView(exercise: exercise)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        exerciseToEdit = exercise
                    }
            }
            .onDelete { offsets in
                Task {
                    await viewModel.deleteExercises(at: offsets)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No exercises found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(viewModel.searchText.isEmpty && viewModel.selectedCategory == nil
                 ? "Tap the + button to add your first exercise"
                 : "Try adjusting your filters")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if !viewModel.searchText.isEmpty || viewModel.selectedCategory != nil {
                Button("Clear Filters") {
                    viewModel.clearFilters()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Supporting Views

struct CategoryChip: View {
    let title: String
    var systemImage: String?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.wrappedName)
                .font(.headline)
            
            HStack {
                Label(exercise.wrappedCategory, systemImage: ExerciseCategory(rawValue: exercise.wrappedCategory)?.systemImage ?? "questionmark.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !exercise.muscleGroupsArray.isEmpty {
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(exercise.muscleGroupsArray.prefix(2).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if exercise.muscleGroupsArray.count > 2 {
                        Text("+\(exercise.muscleGroupsArray.count - 2)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct ExerciseListView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseListView(context: PersistenceController.preview.container.viewContext)
    }
}
