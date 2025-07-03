//
//  CreateWorkoutView.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import SwiftUI
import CoreData

struct CreateWorkoutView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    
    @State private var workoutName = ""
    @State private var workoutDate = Date()
    @State private var workoutNotes = ""
    @State private var selectedExercises: [Exercise] = []
    @State private var showingExercisePicker = false
    @State private var startImmediately = true
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Info Section
                Section(header: Text("Workout Details")) {
                    TextField("Workout Name", text: $workoutName)
                        .autocapitalization(.words)
                    
                    DatePicker("Date", selection: $workoutDate, displayedComponents: [.date, .hourAndMinute])
                    
                    TextEditor(text: $workoutNotes)
                        .frame(minHeight: 60)
                        .placeholder(when: workoutNotes.isEmpty) {
                            Text("Notes (optional)")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                }
                
                // Exercises Section
                Section(header: Text("Exercises")) {
                    if selectedExercises.isEmpty {
                        Button(action: { showingExercisePicker = true }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.accentColor)
                                Text("Add Exercises")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("Optional")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        ForEach(selectedExercises) { exercise in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(exercise.wrappedName)
                                        .font(.subheadline)
                                    Text(exercise.wrappedCategory)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .onDelete { offsets in
                            selectedExercises.remove(atOffsets: offsets)
                        }
                        
                        Button(action: { showingExercisePicker = true }) {
                            Label("Add More", systemImage: "plus.circle")
                                .font(.caption)
                        }
                    }
                }
                
                // Options Section
                Section {
                    Toggle("Start workout immediately", isOn: $startImmediately)
                        .onChange(of: startImmediately) { value in
                            if value {
                                workoutDate = Date()
                            }
                        }
                }
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createWorkout()
                    }
                    .disabled(workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(selectedExercises: $selectedExercises)
            }
        }
    }
    
    private func createWorkout() {
        Task {
            let trimmedName = workoutName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedNotes = workoutNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            
            await viewModel.createWorkout(
                name: trimmedName,
                date: workoutDate,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )
            
            // If exercises were selected, add them to the workout
            if !selectedExercises.isEmpty, let newWorkout = viewModel.workouts.first {
                let repository = WorkoutRepository(context: context)
                for (index, exercise) in selectedExercises.enumerated() {
                    do {
                        _ = try repository.addExercise(exercise, to: newWorkout, order: Int16(index))
                    } catch {
                        print("Error adding exercise to workout: \(error)")
                    }
                }
            }
            
            dismiss()
            
            // If start immediately is selected, navigate to the active workout view
            if startImmediately, let newWorkout = viewModel.workouts.first {
                // This would be handled by the parent view
            }
        }
    }
}

// MARK: - Exercise Picker View

struct ExercisePickerView: View {
    @Binding var selectedExercises: [Exercise]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var exercises: [Exercise] = []
    
    var filteredExercises: [Exercise] {
        var filtered = exercises
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.wrappedCategory == category.rawValue }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.wrappedName.localizedCaseInsensitiveContains(searchText) ||
                exercise.wrappedCategory.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.wrappedName < $1.wrappedName }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search exercises...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryChip(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            action: { selectedCategory = nil }
                        )
                        
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                title: category.rawValue,
                                systemImage: category.systemImage,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Exercise list
                List {
                    ForEach(filteredExercises) { exercise in
                        ExercisePickerRow(
                            exercise: exercise,
                            isSelected: selectedExercises.contains(where: { $0.id == exercise.id })
                        ) {
                            toggleExercise(exercise)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Select Exercises")
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
                }
            }
            .onAppear {
                loadExercises()
            }
        }
    }
    
    private func loadExercises() {
        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
        
        do {
            exercises = try context.fetch(request)
        } catch {
            print("Error loading exercises: \(error)")
        }
    }
    
    private func toggleExercise(_ exercise: Exercise) {
        if let index = selectedExercises.firstIndex(where: { $0.id == exercise.id }) {
            selectedExercises.remove(at: index)
        } else {
            selectedExercises.append(exercise)
        }
    }
}

struct ExercisePickerRow: View {
    let exercise: Exercise
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.wrappedName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(exercise.wrappedCategory)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !exercise.muscleGroupsArray.isEmpty {
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text(exercise.muscleGroupsArray.prefix(2).joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Helper Extensions

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

// MARK: - Preview

struct CreateWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        CreateWorkoutView(
            viewModel: WorkoutViewModel(context: PersistenceController.preview.container.viewContext)
        )
    }
}
