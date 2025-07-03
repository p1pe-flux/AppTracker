//
//  Exercise+Extensions.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import Foundation
import CoreData

extension Exercise {
    // MARK: - Computed Properties
    
    var wrappedName: String {
        name ?? "Unknown Exercise"
    }
    
    var wrappedCategory: String {
        category ?? "Uncategorized"
    }
    
    var wrappedNotes: String {
        notes ?? ""
    }
    
    var muscleGroupsArray: [String] {
        get {
            if let array = muscleGroups as? [String] {
                return array
            } else if let array = muscleGroups as? NSArray as? [String] {
                return array
            }
            return []
        }
        set {
            muscleGroups = NSArray(array: newValue)
        }
    }
    
    var workoutExercisesArray: [WorkoutExercise] {
        let set = workoutExercises as? Set<WorkoutExercise> ?? []
        return set.sorted { ($0.workout?.date ?? Date()) > ($1.workout?.date ?? Date()) }
    }
    
    // MARK: - Static Methods
    
    static func create(
        name: String,
        category: String,
        muscleGroups: [String] = [],
        notes: String? = nil,
        in context: NSManagedObjectContext
    ) -> Exercise {
        let exercise = Exercise(context: context)
        exercise.id = UUID()
        exercise.name = name
        exercise.category = category
        exercise.muscleGroupsArray = muscleGroups
        exercise.notes = notes
        exercise.createdAt = Date()
        exercise.updatedAt = Date()
        return exercise
    }
    
    // MARK: - Instance Methods
    
    func update(
        name: String? = nil,
        category: String? = nil,
        muscleGroups: [String]? = nil,
        notes: String? = nil
    ) {
        if let name = name {
            self.name = name
        }
        if let category = category {
            self.category = category
        }
        if let muscleGroups = muscleGroups {
            self.muscleGroupsArray = muscleGroups
        }
        if let notes = notes {
            self.notes = notes
        }
        self.updatedAt = Date()
    }
}

// MARK: - Exercise Categories

enum ExerciseCategory: String, CaseIterable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case legs = "Legs"
    case core = "Core"
    case cardio = "Cardio"
    case other = "Other"
    
    var systemImage: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.strengthtraining.traditional"
        case .shoulders: return "figure.strengthtraining.traditional"
        case .biceps: return "figure.arms.open"
        case .triceps: return "figure.arms.open"
        case .legs: return "figure.walk"
        case .core: return "figure.core.training"
        case .cardio: return "figure.run"
        case .other: return "questionmark.circle"
        }
    }
}

// MARK: - Muscle Groups

enum MuscleGroup: String, CaseIterable {
    // Chest
    case pectoralMajor = "Pectoral Major"
    case pectoralMinor = "Pectoral Minor"
    
    // Back
    case latissimusDorsi = "Latissimus Dorsi"
    case trapezius = "Trapezius"
    case rhomboids = "Rhomboids"
    case erectorSpinae = "Erector Spinae"
    
    // Shoulders
    case anteriorDeltoid = "Anterior Deltoid"
    case medialDeltoid = "Medial Deltoid"
    case posteriorDeltoid = "Posterior Deltoid"
    
    // Arms
    case bicepsBrachii = "Biceps Brachii"
    case tricepsBrachii = "Triceps Brachii"
    case forearms = "Forearms"
    
    // Legs
    case quadriceps = "Quadriceps"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case hipFlexors = "Hip Flexors"
    case adductors = "Adductors"
    case abductors = "Abductors"
    
    // Core
    case rectusAbdominis = "Rectus Abdominis"
    case obliques = "Obliques"
    case transverseAbdominis = "Transverse Abdominis"
    
    var category: ExerciseCategory {
        switch self {
        case .pectoralMajor, .pectoralMinor:
            return .chest
        case .latissimusDorsi, .trapezius, .rhomboids, .erectorSpinae:
            return .back
        case .anteriorDeltoid, .medialDeltoid, .posteriorDeltoid:
            return .shoulders
        case .bicepsBrachii:
            return .biceps
        case .tricepsBrachii:
            return .triceps
        case .forearms:
            return .other
        case .quadriceps, .hamstrings, .glutes, .calves, .hipFlexors, .adductors, .abductors:
            return .legs
        case .rectusAbdominis, .obliques, .transverseAbdominis:
            return .core
        }
    }
}
