//
//  WorkoutDuplicationService.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 04/07/25.
//

import Foundation
import CoreData

class WorkoutDuplicationService {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Duplicate Workout
    
    func duplicateWorkout(_ workout: Workout, toDate newDate: Date, withName newName: String? = nil) throws -> Workout {
        // Create new workout
        let newWorkout = Workout(context: context)
        newWorkout.id = UUID()
        newWorkout.name = newName ?? "\(workout.wrappedName) (Copy)"
        newWorkout.date = newDate
        newWorkout.notes = workout.notes
        newWorkout.createdAt = Date()
        newWorkout.updatedAt = Date()
        newWorkout.duration = 0 // Reset duration for new workout
        
        // Copy all exercises
        for (index, workoutExercise) in workout.workoutExercisesArray.enumerated() {
            guard let exercise = workoutExercise.exercise else { continue }
            
            let newWorkoutExercise = WorkoutExercise(context: context)
            newWorkoutExercise.id = UUID()
            newWorkoutExercise.workout = newWorkout
            newWorkoutExercise.exercise = exercise
            newWorkoutExercise.order = Int16(index)
            
            // Copy sets but reset completion status
            for set in workoutExercise.setsArray {
                let newSet = WorkoutSet(context: context)
                newSet.id = UUID()
                newSet.workoutExercise = newWorkoutExercise
                newSet.setNumber = set.setNumber
                newSet.weight = set.weight
                newSet.reps = set.reps
                newSet.restTime = set.restTime
                newSet.completed = false // Reset completion
                newSet.createdAt = Date()
            }
        }
        
        try context.save()
        return newWorkout
    }
    
    // MARK: - Create Template from Workout
    
    func createTemplate(from workout: Workout, templateName: String) throws -> WorkoutTemplate {
        let template = WorkoutTemplate(context: context)
        template.id = UUID()
        template.name = templateName
        template.notes = workout.notes
        template.createdAt = Date()
        template.updatedAt = Date()
        
        // Copy exercises as template exercises
        for (index, workoutExercise) in workout.workoutExercisesArray.enumerated() {
            guard let exercise = workoutExercise.exercise else { continue }
            
            let templateExercise = TemplateExercise(context: context)
            templateExercise.id = UUID()
            templateExercise.template = template
            templateExercise.exercise = exercise
            templateExercise.order = Int16(index)
            
            // Store sets configuration
            var setsConfig: [[String: Any]] = []
            for set in workoutExercise.setsArray {
                setsConfig.append([
                    "setNumber": set.setNumber,
                    "weight": set.weight,
                    "reps": set.reps,
                    "restTime": set.restTime
                ])
            }
            templateExercise.setsConfiguration = try? JSONSerialization.data(withJSONObject: setsConfig)
        }
        
        try context.save()
        return template
    }
    
    // MARK: - Create Workout from Template
    
    func createWorkout(from template: WorkoutTemplate, date: Date, name: String? = nil) throws -> Workout {
        let workout = Workout(context: context)
        workout.id = UUID()
        workout.name = name ?? template.wrappedName
        workout.date = date
        workout.notes = template.notes
        workout.createdAt = Date()
        workout.updatedAt = Date()
        
        // Create exercises from template
        for templateExercise in template.exercisesArray {
            guard let exercise = templateExercise.exercise else { continue }
            
            let workoutExercise = WorkoutExercise(context: context)
            workoutExercise.id = UUID()
            workoutExercise.workout = workout
            workoutExercise.exercise = exercise
            workoutExercise.order = templateExercise.order
            
            // Create sets from configuration
            if let setsData = templateExercise.setsConfiguration,
               let setsConfig = try? JSONSerialization.jsonObject(with: setsData) as? [[String: Any]] {
                
                for setConfig in setsConfig {
                    let set = WorkoutSet(context: context)
                    set.id = UUID()
                    set.workoutExercise = workoutExercise
                    set.setNumber = setConfig["setNumber"] as? Int16 ?? 1
                    set.weight = setConfig["weight"] as? Double ?? 0
                    set.reps = setConfig["reps"] as? Int16 ?? 0
                    set.restTime = setConfig["restTime"] as? Int16 ?? 90
                    set.completed = false
                    set.createdAt = Date()
                }
            }
        }
        
        try context.save()
        return workout
    }
}

// MARK: - Core Data Extensions

// Extensions for the auto-generated Core Data classes
extension WorkoutTemplate {
    var wrappedName: String {
        name ?? "Unnamed Template"
    }
    
    var exercisesArray: [TemplateExercise] {
        let set = templateExercises as? Set<TemplateExercise> ?? []
        return set.sorted { $0.order < $1.order }
    }
}

extension TemplateExercise {
    // Add any convenience methods here if needed
}
