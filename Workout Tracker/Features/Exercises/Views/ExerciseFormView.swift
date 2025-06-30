//
//  ExerciseFormView.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import SwiftUI

struct ExerciseFormView: View {
    @ObservedObject var viewModel: ExerciseViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var formData = ExerciseViewModel.ExerciseFormData()
    @State private var showingMuscleGroupPicker = false
    @State private var isSaving = false
    
    let exercise: Exercise?
    
    init(viewModel: ExerciseViewModel, exercise: Exercise? = nil) {
        self.viewModel = viewModel
        self.exercise = exercise
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Name Section
                Section(header: Text("Exercise Name")) {
                    TextField("Enter exercise name", text: $formData.name)
                        .autocapitalization(.words)
                }
                
                // Category Section
                Section(header: Text("Category")) {
                    Picker("Category", selection: $formData.category) {
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.systemImage)
                                .tag(category)
                        }
                    }
                }
                
                // Muscle Groups Section
                Section(header: Text("Muscle Groups")) {
                    if formData.selectedMuscleGroups.isEmpty {
                        Button(action: { showingMuscleGroupPicker = true }) {
                            HStack {
                                Text("Select muscle groups")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                                ForEach(Array(formData.selectedMuscleGroups), id: \.self) { muscleGroup in
                                    MuscleGroupTag(muscleGroup: muscleGroup) {
                                        formData.selectedMuscleGroups.remove(muscleGroup)
                                    }
                                }
                            }
                            
                            Button(action: { showingMuscleGroupPicker = true }) {
                                Label("Add more", systemImage: "plus.circle")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Notes Section
                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: $formData.notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(exercise == nil ? "New Exercise" : "Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExercise()
                    }
                    .disabled(!formData.isValid || isSaving)
                }
            }
            .sheet(isPresented: $showingMuscleGroupPicker) {
                MuscleGroupPickerView(selectedMuscleGroups: $formData.selectedMuscleGroups)
            }
            .onAppear {
                if let exercise = exercise {
                    loadExerciseData(exercise)
                }
            }
        }
    }
    
    private func loadExerciseData(_ exercise: Exercise) {
        formData.name = exercise.wrappedName
        formData.category = ExerciseCategory(rawValue: exercise.wrappedCategory) ?? .other
        formData.selectedMuscleGroups = Set(exercise.muscleGroupsArray.compactMap { MuscleGroup(rawValue: $0) })
        formData.notes = exercise.wrappedNotes
    }
    
    private func saveExercise() {
        isSaving = true
        
        Task {
            if let exercise = exercise {
                await viewModel.updateExercise(
                    exercise,
                    name: formData.trimmedName,
                    category: formData.category.rawValue,
                    muscleGroups: formData.muscleGroupsArray,
                    notes: formData.trimmedNotes.isEmpty ? nil : formData.trimmedNotes
                )
            } else {
                await viewModel.createExercise(
                    name: formData.trimmedName,
                    category: formData.category.rawValue,
                    muscleGroups: formData.muscleGroupsArray,
                    notes: formData.trimmedNotes.isEmpty ? nil : formData.trimmedNotes
                )
            }
            
            dismiss()
        }
    }
}

struct MuscleGroupTag: View {
    let muscleGroup: MuscleGroup
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(muscleGroup.rawValue)
                .font(.caption)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct MuscleGroupPickerView: View {
    @Binding var selectedMuscleGroups: Set<MuscleGroup>
    @Environment(\.dismiss) private var dismiss
    
    var groupedMuscleGroups: [(category: ExerciseCategory, muscles: [MuscleGroup])] {
        let grouped = Dictionary(grouping: MuscleGroup.allCases) { $0.category }
        return grouped
            .map { (category: $0.key, muscles: $0.value) }
            .sorted { $0.category.rawValue < $1.category.rawValue }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(groupedMuscleGroups, id: \.category) { group in
                    Section(header: Text(group.category.rawValue)) {
                        ForEach(group.muscles, id: \.self) { muscle in
                            HStack {
                                Text(muscle.rawValue)
                                Spacer()
                                if selectedMuscleGroups.contains(muscle) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedMuscleGroups.contains(muscle) {
                                    selectedMuscleGroups.remove(muscle)
                                } else {
                                    selectedMuscleGroups.insert(muscle)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Muscle Groups")
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

// MARK: - Preview

struct ExerciseFormView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseFormView(
            viewModel: ExerciseViewModel(context: PersistenceController.preview.container.viewContext)
        )
    }
}
