//
//  WorkoutViewModel.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import Foundation
import CoreData
import Combine

@MainActor
class WorkoutViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var workouts: [Workout] = []
    @Published var todayWorkouts: [Workout] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // MARK: - Properties
    
    private let repository: WorkoutRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(repository: WorkoutRepositoryProtocol) {
        self.repository = repository
        loadWorkouts()
    }
    
    convenience init(context: NSManagedObjectContext) {
        self.init(repository: WorkoutRepository(context: context))
    }
    
    // MARK: - Public Methods
    
    func loadWorkouts() {
        Task {
            await fetchWorkouts()
        }
    }
    
    func createWorkout(name: String, date: Date = Date(), notes: String?) async {
        isLoading = true
        
        do {
            let workout = try repository.create(name: name, date: date, notes: notes)
            workouts.insert(workout, at: 0)
            updateTodayWorkouts()
            isLoading = false
        } catch {
            handleError(error, message: "Failed to create workout")
        }
    }
    
    func updateWorkout(_ workout: Workout, name: String?, date: Date?, notes: String?) async {
        isLoading = true
        
        do {
            try repository.update(workout, name: name, date: date, notes: notes)
            await fetchWorkouts()
        } catch {
            handleError(error, message: "Failed to update workout")
        }
    }
    
    func deleteWorkout(_ workout: Workout) async {
        do {
            try repository.delete(workout)
            workouts.removeAll { $0.id == workout.id }
            updateTodayWorkouts()
        } catch {
            handleError(error, message: "Failed to delete workout")
        }
    }
    
    func deleteWorkouts(at offsets: IndexSet) async {
        for index in offsets {
            if index < workouts.count {
                await deleteWorkout(workouts[index])
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchWorkouts() async {
        isLoading = true
        
        do {
            workouts = try repository.fetchAll()
            todayWorkouts = try repository.fetchToday()
            isLoading = false
        } catch {
            handleError(error, message: "Failed to load workouts")
        }
    }
    
    private func updateTodayWorkouts() {
        todayWorkouts = workouts.filter { workout in
            Calendar.current.isDateInToday(workout.date ?? Date())
        }
    }
    
    private func handleError(_ error: Error, message: String) {
        errorMessage = "\(message): \(error.localizedDescription)"
        showError = true
        isLoading = false
    }
}

// MARK: - Active Workout Management

@MainActor
class ActiveWorkoutViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var workout: Workout?
    @Published var selectedExercises: [Exercise] = []
    @Published var workoutExercises: [WorkoutExercise] = []
    @Published var startTime: Date?
    @Published var elapsedTime: TimeInterval = 0
    @Published var isTimerRunning: Bool = false
    @Published var restTimerSeconds: Int = 0
    @Published var isRestTimerRunning: Bool = false
    
    // MARK: - Properties
    
    private let repository: WorkoutRepository
    private var timer: Timer?
    private var restTimer: Timer?
    
    // MARK: - Initialization
    
    init(repository: WorkoutRepository, workout: Workout? = nil) {
        self.repository = repository
        self.workout = workout
        if let workout = workout {
            self.workoutExercises = workout.workoutExercisesArray
        }
    }
    
    convenience init(context: NSManagedObjectContext, workout: Workout? = nil) {
        self.init(repository: WorkoutRepository(context: context), workout: workout)
    }
    
    // MARK: - Timer Management
    
    func startWorkout() {
        guard workout != nil else { return }
        startTime = Date()
        isTimerRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateElapsedTime()
        }
        
        do {
            try repository.startWorkout(workout!)
        } catch {
            print("Error starting workout: \(error)")
        }
    }
    
    func pauseWorkout() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func resumeWorkout() {
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateElapsedTime()
        }
    }
    
    func endWorkout() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        
        guard let workout = workout else { return }
        
        do {
            try repository.endWorkout(workout, duration: Int32(elapsedTime))
        } catch {
            print("Error ending workout: \(error)")
        }
    }
    
    private func updateElapsedTime() {
        guard let startTime = startTime else { return }
        elapsedTime = Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Rest Timer
    
    func startRestTimer(seconds: Int) {
        restTimerSeconds = seconds
        isRestTimerRunning = true
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateRestTimer()
        }
    }
    
    func stopRestTimer() {
        isRestTimerRunning = false
        restTimer?.invalidate()
        restTimer = nil
        restTimerSeconds = 0
    }
    
    private func updateRestTimer() {
        if restTimerSeconds > 0 {
            restTimerSeconds -= 1
        } else {
            stopRestTimer()
            // Could add notification or sound here
        }
    }
    
    // MARK: - Exercise Management
    
    func addExercise(_ exercise: Exercise) async {
        guard let workout = workout else { return }
        
        do {
            let order = Int16(workoutExercises.count)
            let workoutExercise = try repository.addExercise(exercise, to: workout, order: order)
            workoutExercises.append(workoutExercise)
        } catch {
            print("Error adding exercise: \(error)")
        }
    }
    
    func removeExercise(at offsets: IndexSet) async {
        for index in offsets {
            if index < workoutExercises.count {
                do {
                    try repository.removeExercise(workoutExercises[index])
                    workoutExercises.remove(at: index)
                } catch {
                    print("Error removing exercise: \(error)")
                }
            }
        }
    }
    
    func reorderExercises() async {
        guard let workout = workout else { return }
        
        do {
            try repository.reorderExercises(in: workout, exercises: workoutExercises)
        } catch {
            print("Error reordering exercises: \(error)")
        }
    }
    
    // MARK: - Set Management
    
    func addSet(to workoutExercise: WorkoutExercise) async {
        let setNumber = Int16(workoutExercise.setsArray.count + 1)
        
        // Copy values from last set
        let lastSet = workoutExercise.lastSet
        let weight = lastSet?.weight
        let reps = lastSet?.reps
        let restTime = lastSet?.restTime ?? 90
        
        do {
            _ = try repository.addSet(
                to: workoutExercise,
                setNumber: setNumber,
                weight: weight,
                reps: reps,
                restTime: restTime
            )
            // Refresh workout exercises
            if let workout = workout {
                workoutExercises = workout.workoutExercisesArray
            }
        } catch {
            print("Error adding set: \(error)")
        }
    }
    
    // En ActiveWorkoutViewModel, actualiza este método:

    func updateSet(_ set: WorkoutSet, weight: Double?, reps: Int16?, restTime: Int16?, completed: Bool?) async {
        do {
            try repository.updateSet(set, weight: weight, reps: reps, restTime: restTime, completed: completed)
        } catch {
            print("Error updating set: \(error)")
        }
    }
    
    func deleteSet(_ set: WorkoutSet) async {
        do {
            try repository.deleteSet(set)
            // Refresh workout exercises
            if let workout = workout {
                workoutExercises = workout.workoutExercisesArray
            }
        } catch {
            print("Error deleting set: \(error)")
        }
    }
}
