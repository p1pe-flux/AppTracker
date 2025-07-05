//
//  DuplicateWorkoutView.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 5/7/25.
//


//
//  DuplicateWorkoutView.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 04/07/25.
//

import SwiftUI
import CoreData

struct DuplicateWorkoutView: View {
    let workout: Workout
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    
    @State private var selectedDate = Date()
    @State private var workoutName = ""
    @State private var isDuplicating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let duplicationService: WorkoutDuplicationService
    
    init(workout: Workout) {
        self.workout = workout
        self.duplicationService = WorkoutDuplicationService(
            context: workout.managedObjectContext ?? PersistenceController.shared.container.viewContext
        )
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Original Workout")) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                        Text(workout.wrappedName)
                            .font(.headline)
                        
                        HStack {
                            Label("\(workout.workoutExercisesArray.count) exercises", systemImage: "figure.strengthtraining.traditional")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if workout.totalSets > 0 {
                                Text("•")
                                    .foregroundColor(.secondary)
                                
                                Label("\(workout.totalSets) sets", systemImage: "list.number")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section(header: Text("New Workout Details")) {
                    TextField("Workout Name", text: $workoutName)
                        .autocapitalization(.words)
                    
                    DatePicker("Date", selection: $selectedDate, displayedComponents: [.date])
                }
                
                Section(header: Text("Exercises to Copy")) {
                    ForEach(workout.workoutExercisesArray) { workoutExercise in
                        if let exercise = workoutExercise.exercise {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(exercise.wrappedName)
                                        .font(.subheadline)
                                    
                                    Text("\(workoutExercise.setsArray.count) sets")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.Colors.success)
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: duplicateWorkout) {
                        if isDuplicating {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Duplicating...")
                            }
                        } else {
                            Label("Duplicate Workout", systemImage: "doc.on.doc.fill")
                        }
                    }
                    .disabled(workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isDuplicating)
                }
            }
            .navigationTitle("Duplicate Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                workoutName = "\(workout.wrappedName) (Copy)"
            }
        }
    }
    
    private func duplicateWorkout() {
        isDuplicating = true
        
        Task {
            do {
                _ = try duplicationService.duplicateWorkout(
                    workout,
                    toDate: selectedDate,
                    withName: workoutName.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                HapticManager.shared.notification(.success)
                dismiss()
            } catch {
                errorMessage = "Failed to duplicate workout: \(error.localizedDescription)"
                showError = true
                isDuplicating = false
            }
        }
    }
}

// MARK: - Quick Duplicate Actions

struct QuickDuplicateMenu: View {
    let workout: Workout
    @Environment(\.managedObjectContext) private var context
    @State private var showingSuccess = false
    
    private var duplicationService: WorkoutDuplicationService {
        WorkoutDuplicationService(context: context)
    }
    
    var body: some View {
        Menu {
            Button(action: { duplicateForTomorrow() }) {
                Label("Duplicate for Tomorrow", systemImage: "calendar.badge.plus")
            }
            
            Button(action: { duplicateForNextWeek() }) {
                Label("Duplicate for Next Week", systemImage: "calendar.badge.clock")
            }
            
            Button(action: { /* Show custom date picker */ }) {
                Label("Duplicate for Custom Date...", systemImage: "calendar")
            }
        } label: {
            Label("Duplicate", systemImage: "doc.on.doc")
        }
    }
    
    private func duplicateForTomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        duplicateWorkout(for: tomorrow)
    }
    
    private func duplicateForNextWeek() {
        let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())!
        duplicateWorkout(for: nextWeek)
    }
    
    private func duplicateWorkout(for date: Date) {
        Task {
            do {
                _ = try duplicationService.duplicateWorkout(workout, toDate: date)
                HapticManager.shared.notification(.success)
                showingSuccess = true
            } catch {
                print("Failed to duplicate workout: \(error)")
            }
        }
    }
}