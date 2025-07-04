//
//  EnhancedExerciseFormView.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import SwiftUI

struct EnhancedExerciseFormView: View {
    @ObservedObject var viewModel: ExerciseViewModel
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var formData = ExerciseFormModel()
    @State private var showingMuscleGroupPicker = false
    @State private var showingValidationErrors = false
    @State private var showingSaveSuccess = false
    @State private var isSaving = false
    
    let exercise: Exercise?
    
    init(viewModel: ExerciseViewModel, exercise: Exercise? = nil) {
        self.viewModel = viewModel
        self.exercise = exercise
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: Theme.Spacing.large) {
                        // Exercise Name Section
                        nameSection
                        
                        // Category Section
                        categorySection
                        
                        // Muscle Groups Section
                        muscleGroupsSection
                        
                        // Notes Section
                        notesSection
                        
                        // Validation Errors
                        if showingValidationErrors && !formData.validationErrors.isEmpty {
                            validationErrorsView
                        }
                        
                        // Save Button
                        saveButton
                    }
                    .padding()
                }
                
                // Success Feedback
                VStack {
                    FeedbackView(
                        type: .success,
                        message: exercise == nil ? "Exercise created successfully!" : "Exercise updated successfully!",
                        isPresented: $showingSaveSuccess
                    )
                    .padding()
                    Spacer()
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
            }
            .sheet(isPresented: $showingMuscleGroupPicker) {
                EnhancedMuscleGroupPicker(selectedMuscleGroups: $formData.selectedMuscleGroups)
            }
            .onAppear {
                if let exercise = exercise {
                    loadExerciseData(exercise)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Label("Exercise Name", systemImage: "pencil")
                .font(.headline)
            
            CustomTextField(
                title: "Enter exercise name",
                text: $formData.name,
                autocapitalization: .words
            )
            .onChange(of: formData.name) { _ in
                formData.validateName()
            }
            
            if let error = formData.nameError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(Theme.Colors.error)
                    .transition(.opacity)
            }
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Label("Category", systemImage: "tag")
                .font(.headline)
            
            let categories = ExerciseCategory.allCases
            let columns: [GridItem] = [GridItem(.adaptive(minimum: 100))]
            
            LazyVGrid(columns: columns, spacing: Theme.Spacing.small) {
                ForEach(categories, id: \.rawValue) { (category: ExerciseCategory) in
                    CategorySelectionButton(
                        category: category,
                        isSelected: formData.category == category
                    ) {
                        HapticManager.shared.selection()
                        withAnimation(Theme.Animation.fast) {
                            formData.category = category
                        }
                    }
                }
            }
        }
    }
    
    private var muscleGroupsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack {
                Label("Muscle Groups", systemImage: "figure.arms.open")
                    .font(.headline)
                
                Spacer()
                
                Text("\(formData.selectedMuscleGroups.count) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if formData.selectedMuscleGroups.isEmpty {
                Button(action: { showingMuscleGroupPicker = true }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(Theme.Colors.primary)
                        Text("Select muscle groups")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                }
            } else {
                VStack(spacing: Theme.Spacing.small) {
                    List(formData.sortedMuscleGroups, id: \.self) { muscleGroup in
                        HStack {
                            Text(muscleGroup.rawValue)
                                .font(.caption)
                            
                            Spacer()
                            
                            Button(action: {
                                formData.selectedMuscleGroups.remove(muscleGroup)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .listStyle(PlainListStyle())
                    
                    Button(action: { showingMuscleGroupPicker = true }) {
                        Label("Add more", systemImage: "plus.circle")
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack {
                Label("Notes", systemImage: "note.text")
                    .font(.headline)
                
                Spacer()
                
                Text("\(formData.notes.count)/500")
                    .font(.caption)
                    .foregroundColor(formData.notes.count > 450 ? Theme.Colors.warning : .secondary)
            }
            
            TextEditor(text: $formData.notes)
                .frame(minHeight: 100)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .onChange(of: formData.notes) { _ in
                    formData.validateNotes()
                }
            
            if let error = formData.notesError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(Theme.Colors.error)
                    .transition(.opacity)
            }
        }
    }
    
    private var validationErrorsView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
            ForEach(formData.validationErrors, id: \.self) { error in
                HStack(alignment: .top, spacing: Theme.Spacing.xSmall) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.error)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(Theme.Colors.error)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                .fill(Theme.Colors.error.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .stroke(Theme.Colors.error.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private var saveButton: some View {
        Button(action: saveExercise) {
            if isSaving {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Text("Saving...")
                }
            } else {
                Label(exercise == nil ? "Create Exercise" : "Save Changes", systemImage: "checkmark.circle.fill")
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!formData.isValid || isSaving)
        .padding(.top)
    }
    
    // MARK: - Helper Methods
    
    private func loadExerciseData(_ exercise: Exercise) {
        formData.name = exercise.wrappedName
        formData.category = ExerciseCategory(rawValue: exercise.wrappedCategory) ?? .other
        formData.selectedMuscleGroups = Set(exercise.muscleGroupsArray.compactMap { MuscleGroup(rawValue: $0) })
        formData.notes = exercise.wrappedNotes
    }
    
    private func saveExercise() {
        showingValidationErrors = !formData.isValid
        
        guard formData.isValid else {
            HapticManager.shared.notification(.error)
            return
        }
        
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
            
            HapticManager.shared.notification(.success)
            showingSaveSuccess = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }
}

// MARK: - Form Model

class ExerciseFormModel: ObservableObject {
    @Published var name: String = "" {
        didSet { validateName() }
    }
    @Published var category: ExerciseCategory = .other
    @Published var selectedMuscleGroups: Set<MuscleGroup> = []
    @Published var notes: String = "" {
        didSet { validateNotes() }
    }
    
    @Published var nameError: String?
    @Published var notesError: String?
    
    var isValid: Bool {
        nameError == nil && notesError == nil && !trimmedName.isEmpty
    }
    
    var validationErrors: [String] {
        [nameError, notesError].compactMap { $0 }
    }
    
    var trimmedName: String {
        InputSanitizer.sanitizeTextInput(name, maxLength: 50)
    }
    
    var trimmedNotes: String {
        InputSanitizer.sanitizeTextInput(notes, maxLength: 500)
    }
    
    var muscleGroupsArray: [String] {
        Array(selectedMuscleGroups)
            .map { $0.rawValue }
            .sorted()
    }
    
    var sortedMuscleGroups: [MuscleGroup] {
        selectedMuscleGroups.sorted { $0.rawValue < $1.rawValue }
    }
    
    func validateName() {
        let result = Validators.validateExerciseName(name)
        nameError = result.errorMessage
    }
    
    func validateNotes() {
        let result = Validators.validateNotes(notes)
        notesError = result.errorMessage
    }
}

// MARK: - Supporting Views

struct CategorySelectionButton: View {
    let category: ExerciseCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xSmall) {
                Image(systemName: category.systemImage)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : category.color)
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .fill(isSelected ? category.color : Color(UIColor.tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .stroke(isSelected ? Color.clear : category.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
