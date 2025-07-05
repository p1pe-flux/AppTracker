//
//  ActiveWorkoutView.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import SwiftUI
import CoreData

struct ActiveWorkoutView: View {
    @StateObject private var viewModel: ActiveWorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    
    @State private var showingExercisePicker = false
    @State private var showingEndWorkoutAlert = false
    @State private var expandedExercises: Set<UUID> = []
    
    let workout: Workout
    
    init(workout: Workout) {
        self.workout = workout
        _viewModel = StateObject(wrappedValue: ActiveWorkoutViewModel(
            context: workout.managedObjectContext ?? PersistenceController.shared.container.viewContext,
            workout: workout
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with timer
            workoutHeader
            
            // Exercise list
            if viewModel.workoutExercises.isEmpty {
                emptyState
            } else {
                exercisesList
            }
            
            // Rest timer (if active)
            if viewModel.isRestTimerRunning {
                restTimerView
            }
        }
        .navigationTitle(workout.wrappedName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isTimerRunning)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.isTimerRunning {
                    Button("End") {
                        showingEndWorkoutAlert = true
                    }
                } else {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingExercisePicker = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            AddExerciseToWorkoutView(viewModel: viewModel)
        }
        .alert("End Workout?", isPresented: $showingEndWorkoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End Workout", role: .destructive) {
                viewModel.endWorkout()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to end this workout?")
        }
        .onAppear {
            if !viewModel.isTimerRunning && viewModel.workoutExercises.isEmpty {
                viewModel.startWorkout()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var workoutHeader: some View {
        VStack(spacing: 12) {
            // Timer display
            Text(formatTime(viewModel.elapsedTime))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
            
            // Timer controls
            HStack(spacing: 20) {
                if !viewModel.isTimerRunning && viewModel.startTime == nil {
                    Button(action: { viewModel.startWorkout() }) {
                        Label("Start Workout", systemImage: "play.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                } else if viewModel.isTimerRunning {
                    Button(action: { viewModel.pauseWorkout() }) {
                        Label("Pause", systemImage: "pause.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button(action: { viewModel.resumeWorkout() }) {
                        Label("Resume", systemImage: "play.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // Progress indicator
                if viewModel.workout?.totalSets ?? 0 > 0 {
                    HStack {
                        CircularProgressView(progress: viewModel.workout?.progress ?? 0)
                            .frame(width: 32, height: 32)
                        
                        Text("\(viewModel.workout?.completedSets ?? 0)/\(viewModel.workout?.totalSets ?? 0)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No exercises added")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Tap + to add exercises to your workout")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button("Add Exercises") {
                showingExercisePicker = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var exercisesList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.workoutExercises) { workoutExercise in
                    ExerciseCard(
                        workoutExercise: workoutExercise,
                        isExpanded: expandedExercises.contains(workoutExercise.id ?? UUID()),
                        viewModel: viewModel,
                        onToggleExpand: {
                            toggleExpanded(workoutExercise)
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    private var restTimerView: some View {
        VStack(spacing: 16) {
            Text("Rest Timer")
                .font(.headline)
            
            Text(formatRestTime(viewModel.restTimerSeconds))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.accentColor)
            
            Button("Skip Rest") {
                viewModel.stopRestTimer()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(12)
        .padding()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Helper Methods
    
    private func toggleExpanded(_ workoutExercise: WorkoutExercise) {
        guard let id = workoutExercise.id else { return }
        
        withAnimation(.spring()) {
            if expandedExercises.contains(id) {
                expandedExercises.remove(id)
            } else {
                expandedExercises.insert(id)
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private func formatRestTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Exercise Card

struct ExerciseCard: View {
    let workoutExercise: WorkoutExercise
    let isExpanded: Bool
    @ObservedObject var viewModel: ActiveWorkoutViewModel
    let onToggleExpand: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: onToggleExpand) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workoutExercise.exercise?.wrappedName ?? "Unknown Exercise")
                            .font(.headline)
                        
                        if let category = workoutExercise.exercise?.wrappedCategory {
                            Text(category)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if workoutExercise.completedSetsCount > 0 {
                            Text("\(workoutExercise.completedSetsCount)/\(workoutExercise.setsArray.count)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 8) {
                    // Sets header
                    HStack {
                        Text("SET")
                            .frame(width: 40, alignment: .leading)
                        Text("WEIGHT")
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("REPS")
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("")
                            .frame(width: 44)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    // Sets list
                    ForEach(workoutExercise.setsArray) { set in
                        EnhancedSetRow(set: set, viewModel: viewModel)
                    }
                    
                    // Add set button
                    Button(action: {
                        Task {
                            await viewModel.addSet(to: workoutExercise)
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Set")
                        }
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    }
                    .padding(.top, 4)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Set Row

struct SetRow: View {
    let set: WorkoutSet
    @ObservedObject var viewModel: ActiveWorkoutViewModel
    
    @State private var weight: String = ""
    @State private var reps: String = ""
    @State private var isEditing = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Set number
            Text("\(set.setNumber)")
                .frame(width: 40, alignment: .leading)
                .foregroundColor(set.completed ? .secondary : .primary)
            
            // Weight input
            TextField("0", text: $weight)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(8)
                .onChange(of: weight) { _, _ in updateSet() }
            
            // Reps input
            TextField("0", text: $reps)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(8)
                .onChange(of: reps) { _, _ in updateSet() }
            
            // Complete button
            Button(action: {
                Task {
                    await viewModel.updateSet(set, weight: nil, reps: nil, restTime: nil, completed: !set.completed)
                    
                    // Start rest timer if completing a set
                    if !set.completed && set.restTime > 0 {
                        viewModel.startRestTimer(seconds: Int(set.restTime))
                    }
                }
            }) {
                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(set.completed ? .green : .secondary)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .onAppear {
            weight = set.weight > 0 ? set.formattedWeight : ""
            reps = set.reps > 0 ? "\(set.reps)" : ""
        }
    }
    
    
    private func updateSet() {
        Task {
            let weightValue = Double(weight) ?? 0
            let repsValue = Int16(reps) ?? 0
            
            await viewModel.updateSet(set, weight: weightValue, reps: repsValue, restTime: nil, completed: nil)
        }
    }
}

// MARK: - Add Exercise to Workout View

struct AddExerciseToWorkoutView: View {
    @ObservedObject var viewModel: ActiveWorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var exercises: [Exercise] = []
    
    var filteredExercises: [Exercise] {
        var filtered = exercises
        
        // Filter out already added exercises
        let addedExerciseIds = Set(viewModel.workoutExercises.compactMap { $0.exercise?.id })
        filtered = filtered.filter { !addedExerciseIds.contains($0.id!) }
        
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
                // Search and filter UI (similar to ExercisePickerView)
                List {
                    ForEach(filteredExercises) { exercise in
                        Button(action: {
                            Task {
                                await viewModel.addExercise(exercise)
                                dismiss()
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.wrappedName)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    
                                    Text(exercise.wrappedCategory)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
}

// MARK: - Preview

struct ActiveWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let workout = Workout(context: context)
        workout.name = "Sample Workout"
        workout.date = Date()
        
        return NavigationView {
            ActiveWorkoutView(workout: workout)
        }
    }
}
