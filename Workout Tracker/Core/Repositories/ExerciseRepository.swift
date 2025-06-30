//
//  ExerciseRepository.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import Foundation
import CoreData
import Combine

protocol ExerciseRepositoryProtocol {
    func create(name: String, category: String, muscleGroups: [String], notes: String?) throws -> Exercise
    func fetchAll() throws -> [Exercise]
    func fetch(by id: UUID) throws -> Exercise?
    func fetchByCategory(_ category: String) throws -> [Exercise]
    func search(query: String) throws -> [Exercise]
    func update(_ exercise: Exercise, name: String?, category: String?, muscleGroups: [String]?, notes: String?) throws
    func delete(_ exercise: Exercise) throws
    func deleteAll() throws
}

class ExerciseRepository: ExerciseRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Create
    
    func create(name: String, category: String, muscleGroups: [String] = [], notes: String? = nil) throws -> Exercise {
        let exercise = Exercise.create(
            name: name,
            category: category,
            muscleGroups: muscleGroups,
            notes: notes,
            in: context
        )
        
        try context.save()
        return exercise
    }
    
    // MARK: - Read
    
    func fetchAll() throws -> [Exercise] {
        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
        return try context.fetch(request)
    }
    
    func fetch(by id: UUID) throws -> Exercise? {
        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    func fetchByCategory(_ category: String) throws -> [Exercise] {
        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
        return try context.fetch(request)
    }
    
    func search(query: String) throws -> [Exercise] {
        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        
        if !query.isEmpty {
            let namePredicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
            let categoryPredicate = NSPredicate(format: "category CONTAINS[cd] %@", query)
            let notesPredicate = NSPredicate(format: "notes CONTAINS[cd] %@", query)
            
            request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                namePredicate,
                categoryPredicate,
                notesPredicate
            ])
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
        return try context.fetch(request)
    }
    
    // MARK: - Update
    
    func update(_ exercise: Exercise, name: String? = nil, category: String? = nil, muscleGroups: [String]? = nil, notes: String? = nil) throws {
        exercise.update(
            name: name,
            category: category,
            muscleGroups: muscleGroups,
            notes: notes
        )
        
        try context.save()
    }
    
    // MARK: - Delete
    
    func delete(_ exercise: Exercise) throws {
        context.delete(exercise)
        try context.save()
    }
    
    func deleteAll() throws {
        let request: NSFetchRequest<NSFetchRequestResult> = Exercise.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        try context.execute(deleteRequest)
        try context.save()
    }
}

// MARK: - Preview/Testing Helper

extension ExerciseRepository {
    static func createPreviewExercises(in context: NSManagedObjectContext) {
        let repository = ExerciseRepository(context: context)
        
        let exercises = [
            (name: "Bench Press", category: ExerciseCategory.chest.rawValue, muscleGroups: [MuscleGroup.pectoralMajor.rawValue, MuscleGroup.tricepsBrachii.rawValue]),
            (name: "Squat", category: ExerciseCategory.legs.rawValue, muscleGroups: [MuscleGroup.quadriceps.rawValue, MuscleGroup.glutes.rawValue]),
            (name: "Deadlift", category: ExerciseCategory.back.rawValue, muscleGroups: [MuscleGroup.erectorSpinae.rawValue, MuscleGroup.glutes.rawValue, MuscleGroup.hamstrings.rawValue]),
            (name: "Pull-up", category: ExerciseCategory.back.rawValue, muscleGroups: [MuscleGroup.latissimusDorsi.rawValue, MuscleGroup.bicepsBrachii.rawValue]),
            (name: "Shoulder Press", category: ExerciseCategory.shoulders.rawValue, muscleGroups: [MuscleGroup.anteriorDeltoid.rawValue, MuscleGroup.medialDeltoid.rawValue]),
            (name: "Bicep Curl", category: ExerciseCategory.biceps.rawValue, muscleGroups: [MuscleGroup.bicepsBrachii.rawValue]),
            (name: "Tricep Extension", category: ExerciseCategory.triceps.rawValue, muscleGroups: [MuscleGroup.tricepsBrachii.rawValue]),
            (name: "Plank", category: ExerciseCategory.core.rawValue, muscleGroups: [MuscleGroup.rectusAbdominis.rawValue, MuscleGroup.transverseAbdominis.rawValue]),
            (name: "Running", category: ExerciseCategory.cardio.rawValue, muscleGroups: [])
        ]
        
        for exercise in exercises {
            do {
                try repository.create(
                    name: exercise.name,
                    category: exercise.category,
                    muscleGroups: exercise.muscleGroups
                )
            } catch {
                print("Error creating preview exercise: \(error)")
            }
        }
    }
}
