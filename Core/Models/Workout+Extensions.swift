//
//  Workout+Extensions.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import Foundation
import CoreData

// MARK: - Workout Extensions

extension Workout {
    var wrappedName: String {
        name ?? "Unnamed Workout"
    }
    
    var wrappedNotes: String {
        notes ?? ""
    }
    
    var workoutExercisesArray: [WorkoutExercise] {
        let set = workoutExercises as? Set<WorkoutExercise> ?? []
        return set.sorted { $0.order < $1.order }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date ?? Date())
    }
    
    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var totalSets: Int {
        workoutExercisesArray.reduce(0) { total, exercise in
            total + exercise.setsArray.count
        }
    }
    
    var completedSets: Int {
        workoutExercisesArray.reduce(0) { total, exercise in
            total + exercise.setsArray.filter { $0.completed }.count
        }
    }
    
    var progress: Double {
        guard totalSets > 0 else { return 0 }
        return Double(completedSets) / Double(totalSets)
    }
    
    var isCompleted: Bool {
        totalSets > 0 && completedSets == totalSets
    }
    
    var totalVolume: Double {
        workoutExercisesArray.reduce(0) { total, exercise in
            total + exercise.totalVolume
        }
    }
}

// MARK: - WorkoutExercise Extensions

extension WorkoutExercise {
    var setsArray: [WorkoutSet] {
        let set = sets as? Set<WorkoutSet> ?? []
        return set.sorted { $0.setNumber < $1.setNumber }
    }
    
    var totalVolume: Double {
        setsArray.reduce(0) { total, set in
            total + (set.completed ? Double(set.weight) * Double(set.reps) : 0)
        }
    }
    
    var completedSetsCount: Int {
        setsArray.filter { $0.completed }.count
    }
    
    var lastSet: WorkoutSet? {
        setsArray.last
    }
    
    func addNewSet() -> WorkoutSet? {
        guard let context = managedObjectContext else { return nil }
        
        let newSet = WorkoutSet(context: context)
        newSet.id = UUID()
        newSet.workoutExercise = self
        newSet.setNumber = Int16((setsArray.last?.setNumber ?? 0) + 1)
        newSet.createdAt = Date()
        
        // Copy values from last set if exists
        if let lastSet = lastSet {
            newSet.weight = lastSet.weight
            newSet.reps = lastSet.reps
            newSet.restTime = lastSet.restTime
        }
        
        return newSet
    }
}

// MARK: - WorkoutSet Extensions

extension WorkoutSet {
    var formattedWeight: String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", weight)
        } else {
            return String(format: "%.1f", weight)
        }
    }
    
    var formattedRestTime: String {
        let minutes = Int(restTime) / 60
        let seconds = Int(restTime) % 60
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
    
    var volume: Double {
        Double(weight) * Double(reps)
    }
}
