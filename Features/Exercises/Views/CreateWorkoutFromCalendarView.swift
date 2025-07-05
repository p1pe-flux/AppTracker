//
//  CreateWorkoutFromCalendarView.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 5/7/25.
//


//
//  CreateWorkoutFromCalendarView.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 04/07/25.
//

import SwiftUI
import CoreData

struct CreateWorkoutFromCalendarView: View {
    let selectedDate: Date
    @ObservedObject var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    
    @State private var workoutName = ""
    @State private var workoutNotes = ""
    @State private var selectedExercises: [Exercise] = []
    @State private var showingExercisePicker = false
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var showingTemplatePicker = false
    @State private var creationMethod: CreationMethod = .blank
    
    enum CreationMethod: String, CaseIterable {
        case blank = "Start from Blank"
        case template = "Use Template"
        case duplicate = "Duplicate Recent"
        
        var icon: String {
            switch self {
            case .blank: return "doc.badge.plus"
            case .template: return "doc.text"
            case .duplicate: return "doc.on.doc"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Date header
                dateHeader
                
                // Creation method selector
                creationMethodSelector
                
                // Content based on method
                Group {
                    switch creationMethod {
                    case .blank:
                        blankWorkoutForm
                    case .template:
                        templateSelectionView
                    case .duplicate:
                        recentWorkoutsView
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
                    .disabled(!canCreateWorkout)
                    .fontWeight(.medium)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(selectedExercises: $selectedExercises)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var dateHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Scheduled for")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(selectedDate.formatted(date: .complete, time: .omitted))
                    .font(.headline)
            }
            
            Spacer()
            
            Image(systemName: "calendar.badge.plus")
                .font(.title2)
                .foregroundColor(Theme.Colors.primary)
        }
        .padding()
        .background(Theme.Colors.primary.opacity(0.1))
    }
    
    private var creationMethodSelector: some View {
        Picker("Creation Method", selection: $creationMethod) {
            ForEach(CreationMethod.allCases, id: \.self) { method in
                Label(method.rawValue, systemImage: method.icon)
                    .tag(method)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
    
    private var blankWorkoutForm: some View {
        Form {
            Section(header: Text("Workout Details")) {
                TextField("Workout Name", text: $workoutName)
                    .autocapitalization(.words)
                
                TextEditor(text: $workoutNotes)
                    .frame(minHeight: 60)
                    .placeholder(when: workoutNotes.isEmpty) {
                        Text("Notes (optional)")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
            }
            
            Section(header: Text("Exercises")) {
                if selectedExercises.isEmpty {
                    Button(action: { showingExercisePicker = true }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.accentColor)
                            Text("Add Exercises")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                } else {
                    ForEach(selectedExercises) { exercise in
                        ExerciseRowForSelection(exercise: exercise)
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
        }
    }
    
    private var templateSelectionView: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.medium) {
                if templates.isEmpty {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "No Templates",
                        message: "Create templates from your completed workouts",
                        actionTitle: nil,
                        action: nil
                    )
                    .frame(height: 300)
                } else {
                    ForEach(templates) { template in
                        TemplateCard(
                            template: template,
                            isSelected: selectedTemplate?.id == template.id
                        ) {
                            selectedTemplate = template
                            workoutName = template.wrappedName
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var recentWorkoutsView: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.medium) {
                ForEach(recentWorkouts) { workout in
                    RecentWorkoutCard(workout: workout) {
                        duplicateWorkout(workout)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Properties
    
    private var canCreateWorkout: Bool {
        switch creationMethod {
        case .blank:
            return !workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .template:
            return selectedTemplate != nil
        case .duplicate:
            return false // Handled directly
        }
    }
    
    private var templates: [WorkoutTemplate] {
        // Fetch templates from Core Data
        []
    }
    
    private var recentWorkouts: [Workout] {
        // Fetch recent workouts
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.date, ascending: false)]
        request.fetchLimit = 10
        
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
    
    // MARK: - Actions
    
    private func createWorkout() {
        Task {
            switch creationMethod {
            case .blank:
                await createBlankWorkout()
            case .template:
                await createFromTemplate()
            case .duplicate:
                break // Handled directly
            }
        }
    }
    
    private func createBlankWorkout() async {
        await viewModel.createWorkout(
            name: workoutName.trimmingCharacters(in: .whitespacesAndNewlines),
            date: selectedDate,
            notes: workoutNotes.isEmpty ? nil : workoutNotes
        )
        
        // Add exercises if selected
        if !selectedExercises.isEmpty, let newWorkout = viewModel.workouts.first(where: { $0.date == selectedDate }) {
            let repository = WorkoutRepository(context: context)
            for (index, exercise) in selectedExercises.enumerated() {
                do {
                    _ = try repository.addExercise(exercise, to: newWorkout, order: Int16(index))
                } catch {
                    print("Error adding exercise: \(error)")
                }
            }
        }
        
        HapticManager.shared.notification(.success)
        dismiss()
    }
    
    private func createFromTemplate() async {
        guard let template = selectedTemplate else { return }
        
        let duplicationService = WorkoutDuplicationService(context: context)
        do {
            _ = try duplicationService.createWorkout(from: template, date: selectedDate, name: workoutName)
            HapticManager.shared.notification(.success)
            dismiss()
        } catch {
            print("Error creating from template: \(error)")
        }
    }
    
    private func duplicateWorkout(_ workout: Workout) {
        let duplicationService = WorkoutDuplicationService(context: context)
        Task {
            do {
                _ = try duplicationService.duplicateWorkout(workout, toDate: selectedDate)
                HapticManager.shared.notification(.success)
                dismiss()
            } catch {
                print("Error duplicating workout: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views

struct ExerciseRowForSelection: View {
    let exercise: Exercise
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(exercise.wrappedName)
                    .font(.subheadline)
                
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
        }
    }
}

struct TemplateCard: View {
    let template: WorkoutTemplate
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                HStack {
                    Text(template.wrappedName)
                        .font(.headline)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
                
                HStack {
                    Label("\(template.exercisesArray.count) exercises", systemImage: "figure.strengthtraining.traditional")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let createdAt = template.createdAt {
                        Text("Created \(createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(isSelected ? Theme.Colors.primary.opacity(0.1) : Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentWorkoutCard: View {
    let workout: Workout
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    Text(workout.wrappedName)
                        .font(.headline)
                    
                    HStack {
                        if let date = workout.date {
                            Label(date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if workout.workoutExercisesArray.count > 0 {
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text("\(workout.workoutExercisesArray.count) exercises")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(Theme.Colors.primary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}