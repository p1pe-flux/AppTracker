//
//  ExerciseViewModel.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import Foundation
import CoreData
import Combine

@MainActor
class ExerciseViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var exercises: [Exercise] = []
    @Published var filteredExercises: [Exercise] = []
    @Published var selectedCategory: ExerciseCategory?
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // MARK: - Properties
    
    private let repository: ExerciseRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var categories: [ExerciseCategory] {
        ExerciseCategory.allCases
    }
    
    var groupedExercises: [String: [Exercise]] {
        Dictionary(grouping: filteredExercises) { $0.wrappedCategory }
    }
    
    // MARK: - Initialization
    
    init(repository: ExerciseRepositoryProtocol) {
        self.repository = repository
        setupBindings()
        loadExercises()
    }
    
    convenience init(context: NSManagedObjectContext) {
        self.init(repository: ExerciseRepository(context: context))
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Filter exercises when search text or category changes
        Publishers.CombineLatest($searchText, $selectedCategory)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText, category in
                self?.filterExercises(searchText: searchText, category: category)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func loadExercises() {
        Task {
            await fetchExercises()
        }
    }
    
    func createExercise(name: String, category: String, muscleGroups: [String], notes: String?) async {
        isLoading = true
        
        do {
            let exercise = try repository.create(
                name: name,
                category: category,
                muscleGroups: muscleGroups,
                notes: notes
            )
            exercises.append(exercise)
            filterExercises(searchText: searchText, category: selectedCategory)
            isLoading = false
        } catch {
            handleError(error, message: "Failed to create exercise")
        }
    }
    
    func updateExercise(_ exercise: Exercise, name: String?, category: String?, muscleGroups: [String]?, notes: String?) async {
        isLoading = true
        
        do {
            try repository.update(exercise, name: name, category: category, muscleGroups: muscleGroups, notes: notes)
            await fetchExercises()
        } catch {
            handleError(error, message: "Failed to update exercise")
        }
    }
    
    func deleteExercise(_ exercise: Exercise) async {
        do {
            try repository.delete(exercise)
            exercises.removeAll { $0.id == exercise.id }
            filterExercises(searchText: searchText, category: selectedCategory)
        } catch {
            handleError(error, message: "Failed to delete exercise")
        }
    }
    
    func deleteExercises(at offsets: IndexSet) async {
        for index in offsets {
            if index < filteredExercises.count {
                await deleteExercise(filteredExercises[index])
            }
        }
    }
    
    func selectCategory(_ category: ExerciseCategory?) {
        selectedCategory = category
    }
    
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
    }
    
    // MARK: - Private Methods
    
    private func fetchExercises() async {
        isLoading = true
        
        do {
            exercises = try repository.fetchAll()
            filterExercises(searchText: searchText, category: selectedCategory)
            isLoading = false
        } catch {
            handleError(error, message: "Failed to load exercises")
        }
    }
    
    private func filterExercises(searchText: String, category: ExerciseCategory?) {
        var filtered = exercises
        
        // Filter by category
        if let category = category {
            filtered = filtered.filter { $0.wrappedCategory == category.rawValue }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.wrappedName.localizedCaseInsensitiveContains(searchText) ||
                exercise.wrappedCategory.localizedCaseInsensitiveContains(searchText) ||
                exercise.muscleGroupsArray.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                exercise.wrappedNotes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort alphabetically
        filteredExercises = filtered.sorted { $0.wrappedName < $1.wrappedName }
    }
    
    private func handleError(_ error: Error, message: String) {
        errorMessage = "\(message): \(error.localizedDescription)"
        showError = true
        isLoading = false
    }
}

// MARK: - Form Validation

extension ExerciseViewModel {
    struct ExerciseFormData {
        var name: String = ""
        var category: ExerciseCategory = .other
        var selectedMuscleGroups: Set<MuscleGroup> = []
        var notes: String = ""
        
        var isValid: Bool {
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        var trimmedName: String {
            name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        var trimmedNotes: String {
            notes.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        var muscleGroupsArray: [String] {
            Array(selectedMuscleGroups).map { $0.rawValue }
        }
    }
}
