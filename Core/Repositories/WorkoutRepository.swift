//
//  WorkoutRepository.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import Foundation
import CoreData
import Combine

protocol WorkoutRepositoryProtocol {
    func create(name: String, date: Date, notes: String?) throws -> Workout
    func fetchAll() throws -> [Workout]
    func fetch(by id: UUID) throws -> Workout?
    func fetchByDateRange(from startDate: Date, to endDate: Date) throws -> [Workout]
    func fetchToday() throws -> [Workout]
    func update(_ workout: Workout, name: String?, date: Date?, notes: String?) throws
    func delete(_ workout: Workout) throws
    func startWorkout(_ workout: Workout) throws
    func endWorkout(_ workout: Workout, duration: Int32) throws
}

class WorkoutRepository: WorkoutRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Create
    
    func create(name: String, date: Date = Date(), notes: String? = nil) throws -> Workout {
        let workout = Workout(context: context)
        workout.id = UUID()
        workout.name = name
        workout.date = date
        workout.notes = notes
        workout.createdAt = Date()
        workout.updatedAt = Date()
        
        try context.save()
        return workout
    }
    
    // MARK: - Read
    
    func fetchAll() throws -> [Workout] {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.date, ascending: false)]
        return try context.fetch(request)
    }
    
    func fetch(by id: UUID) throws -> Workout? {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    func fetchByDateRange(from startDate: Date, to endDate: Date) throws -> [Workout] {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as CVarArg, endDate as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.date, ascending: false)]
        return try context.fetch(request)
    }
    
    func fetchToday() throws -> [Workout] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try fetchByDateRange(from: startOfDay, to: endOfDay)
    }
    
    // MARK: - Update
    
    func update(_ workout: Workout, name: String? = nil, date: Date? = nil, notes: String? = nil) throws {
        if let name = name {
            workout.name = name
        }
        if let date = date {
            workout.date = date
        }
        if let notes = notes {
            workout.notes = notes
        }
        workout.updatedAt = Date()
        
        try context.save()
    }
    
    func startWorkout(_ workout: Workout) throws {
        workout.date = Date()
        workout.updatedAt = Date()
        try context.save()
    }
    
    func endWorkout(_ workout: Workout, duration: Int32) throws {
        workout.duration = duration
        workout.updatedAt = Date()
        try context.save()
    }
    
    // MARK: - Delete
    
    func delete(_ workout: Workout) throws {
        context.delete(workout)
        try context.save()
    }
}

// MARK: - WorkoutExercise Repository Methods

extension WorkoutRepository {
    func addExercise(_ exercise: Exercise, to workout: Workout, order: Int16) throws -> WorkoutExercise {
        let workoutExercise = WorkoutExercise(context: context)
        workoutExercise.id = UUID()
        workoutExercise.workout = workout
        workoutExercise.exercise = exercise
        workoutExercise.order = order
        
        try context.save()
        return workoutExercise
    }
    
    func removeExercise(_ workoutExercise: WorkoutExercise) throws {
        context.delete(workoutExercise)
        try context.save()
    }
    
    func reorderExercises(in workout: Workout, exercises: [WorkoutExercise]) throws {
        for (index, exercise) in exercises.enumerated() {
            exercise.order = Int16(index)
        }
        try context.save()
    }
}

// MARK: - WorkoutSet Repository Methods

extension WorkoutRepository {
    func addSet(to workoutExercise: WorkoutExercise, setNumber: Int16, weight: Double?, reps: Int16?, restTime: Int16?) throws -> WorkoutSet {
        let set = WorkoutSet(context: context)
        set.id = UUID()
        set.workoutExercise = workoutExercise
        set.setNumber = setNumber
        set.weight = weight ?? 0
        set.reps = reps ?? 0
        set.restTime = restTime ?? 0
        set.completed = false
        set.createdAt = Date()
        
        try context.save()
        return set
    }
    
    func updateSet(_ set: WorkoutSet, weight: Double?, reps: Int16?, restTime: Int16?, completed: Bool?) throws {
        if let weight = weight {
            set.weight = weight
        }
        if let reps = reps {
            set.reps = reps
        }
        if let restTime = restTime {
            set.restTime = restTime
        }
        if let completed = completed {
            set.completed = completed
        }
        
        try context.save()
    }
    
    func deleteSet(_ set: WorkoutSet) throws {
        context.delete(set)
        try context.save()
    }
}

// MARK: - Preview/Testing Helper

extension WorkoutRepository {
    static func createPreviewWorkouts(in context: NSManagedObjectContext) {
        let repository = WorkoutRepository(context: context)
        let exerciseRepo = ExerciseRepository(context: context)
        
        do {
            // Fetch some exercises
            let exercises = try exerciseRepo.fetchAll()
            guard exercises.count >= 3 else { return }
            
            // Create a workout from yesterday
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let workout1 = try repository.create(name: "Upper Body Day", date: yesterday, notes: "Felt strong today!")
            
            // Add exercises to workout
            let workoutExercise1 = try repository.addExercise(exercises[0], to: workout1, order: 0)
            let workoutExercise2 = try repository.addExercise(exercises[1], to: workout1, order: 1)
            
            // Add sets
            _ = try repository.addSet(to: workoutExercise1, setNumber: 1, weight: 135, reps: 12, restTime: 90)
            _ = try repository.addSet(to: workoutExercise1, setNumber: 2, weight: 145, reps: 10, restTime: 90)
            _ = try repository.addSet(to: workoutExercise1, setNumber: 3, weight: 155, reps: 8, restTime: 90)
            
            _ = try repository.addSet(to: workoutExercise2, setNumber: 1, weight: 30, reps: 15, restTime: 60)
            _ = try repository.addSet(to: workoutExercise2, setNumber: 2, weight: 35, reps: 12, restTime: 60)
            
            // Create today's workout (not started)
            _ = try repository.create(name: "Leg Day", date: Date(), notes: nil)
            
        } catch {
            print("Error creating preview workouts: \(error)")
        }
    }
}
