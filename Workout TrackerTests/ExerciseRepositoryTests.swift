//
//  ExerciseRepositoryTests.swift
//  Workout TrackerTests
//
//  Created by Felipe Guasch on 29/6/25.
//

import XCTest
import CoreData
@testable import Workout_Tracker

final class ExerciseRepositoryTests: XCTestCase {
    var repository: ExerciseRepository!
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
        repository = ExerciseRepository(context: context)
    }
    
    override func tearDown() {
        repository = nil
        context = nil
        persistenceController = nil
        super.tearDown()
    }
    
    // MARK: - Create Tests
    
    func testCreateExercise() throws {
        // Arrange
        let name = "Bench Press"
        let category = "Chest"  // Use string directly instead of enum
        let muscleGroups = ["Pectoral Major", "Triceps Brachii"]  // Use strings directly
        let notes = "Compound chest exercise"
        
        // Act
        let exercise = try repository.create(
            name: name,
            category: category,
            muscleGroups: muscleGroups,
            notes: notes
        )
        
        // Assert
        XCTAssertNotNil(exercise)
        XCTAssertEqual(exercise.name, name)
        XCTAssertEqual(exercise.category, category)
        XCTAssertEqual(exercise.muscleGroupsArray, muscleGroups)
        XCTAssertEqual(exercise.notes, notes)
        XCTAssertNotNil(exercise.id)
        XCTAssertNotNil(exercise.createdAt)
        XCTAssertNotNil(exercise.updatedAt)
    }
    
    func testCreateExerciseWithMinimalData() throws {
        // Arrange
        let name = "Pull-up"
        let category = "Back"  // Use string directly
        
        // Act
        let exercise = try repository.create(name: name, category: category)
        
        // Assert
        XCTAssertNotNil(exercise)
        XCTAssertEqual(exercise.name, name)
        XCTAssertEqual(exercise.category, category)
        XCTAssertTrue(exercise.muscleGroupsArray.isEmpty)
        XCTAssertNil(exercise.notes)
    }
    
    // MARK: - Read Tests
    
    func testFetchAllExercises() throws {
        // Arrange
        let exercises = [
            ("Squat", "Legs"),
            ("Deadlift", "Back"),
            ("Bench Press", "Chest")
        ]
        
        for (name, category) in exercises {
            _ = try repository.create(name: name, category: category)
        }
        
        // Act
        let fetchedExercises = try repository.fetchAll()
        
        // Assert
        XCTAssertEqual(fetchedExercises.count, 3)
        XCTAssertTrue(fetchedExercises.map { $0.name }.contains("Squat"))
        XCTAssertTrue(fetchedExercises.map { $0.name }.contains("Deadlift"))
        XCTAssertTrue(fetchedExercises.map { $0.name }.contains("Bench Press"))
        
        // Verify sorting
        let names = fetchedExercises.map { $0.name ?? "" }
        XCTAssertEqual(names, names.sorted())
    }
    
    func testFetchExerciseById() throws {
        // Arrange
        let exercise = try repository.create(name: "Plank", category: "Core")
        
        // Act
        let fetchedExercise = try repository.fetch(by: exercise.id!)
        
        // Assert
        XCTAssertNotNil(fetchedExercise)
        XCTAssertEqual(fetchedExercise?.id, exercise.id)
        XCTAssertEqual(fetchedExercise?.name, "Plank")
    }
    
    func testFetchExerciseByInvalidId() throws {
        // Act
        let fetchedExercise = try repository.fetch(by: UUID())
        
        // Assert
        XCTAssertNil(fetchedExercise)
    }
    
    func testFetchExercisesByCategory() throws {
        // Arrange
        _ = try repository.create(name: "Bench Press", category: "Chest")
        _ = try repository.create(name: "Incline Press", category: "Chest")
        _ = try repository.create(name: "Squat", category: "Legs")
        
        // Act
        let chestExercises = try repository.fetchByCategory("Chest")
        
        // Assert
        XCTAssertEqual(chestExercises.count, 2)
        XCTAssertTrue(chestExercises.allSatisfy { $0.category == "Chest" })
    }
    
    func testSearchExercises() throws {
        // Arrange
        _ = try repository.create(
            name: "Bench Press",
            category: "Chest",
            notes: "Compound movement"
        )
        _ = try repository.create(
            name: "Dumbbell Press",
            category: "Chest"
        )
        _ = try repository.create(
            name: "Leg Press",
            category: "Legs"
        )
        
        // Act - Search by name
        let pressExercises = try repository.search(query: "press")
        
        // Assert
        XCTAssertEqual(pressExercises.count, 3)
        
        // Act - Search by notes
        let compoundExercises = try repository.search(query: "compound")
        
        // Assert
        XCTAssertEqual(compoundExercises.count, 1)
        XCTAssertEqual(compoundExercises.first?.name, "Bench Press")
    }
    
    // MARK: - Update Tests
    
    func testUpdateExercise() throws {
        // Arrange
        let exercise = try repository.create(
            name: "Squat",
            category: "Legs"
        )
        let originalUpdatedAt = exercise.updatedAt
        
        // Small delay to ensure updatedAt changes
        Thread.sleep(forTimeInterval: 0.1)
        
        // Act
        try repository.update(
            exercise,
            name: "Back Squat",
            category: "Legs",
            muscleGroups: ["Quadriceps", "Glutes"],
            notes: "Primary leg exercise"
        )
        
        // Assert
        XCTAssertEqual(exercise.name, "Back Squat")
        XCTAssertEqual(exercise.muscleGroupsArray.count, 2)
        XCTAssertEqual(exercise.notes, "Primary leg exercise")
        XCTAssertGreaterThan(exercise.updatedAt!, originalUpdatedAt!)
    }
    
    // MARK: - Delete Tests
    
    func testDeleteExercise() throws {
        // Arrange
        let exercise = try repository.create(name: "Curl", category: "Biceps")
        let exerciseId = exercise.id!
        
        // Act
        try repository.delete(exercise)
        
        // Assert
        let fetchedExercise = try repository.fetch(by: exerciseId)
        XCTAssertNil(fetchedExercise)
        
        let allExercises = try repository.fetchAll()
        XCTAssertEqual(allExercises.count, 0)
    }
    
    func testDeleteAllExercises() throws {
        // Arrange
        for i in 1...5 {
            _ = try repository.create(name: "Exercise \(i)", category: "Other")
        }
        
        // Act
        try repository.deleteAll()
        
        // Assert
        let allExercises = try repository.fetchAll()
        XCTAssertEqual(allExercises.count, 0)
    }
}
