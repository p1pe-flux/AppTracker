//
//  AnalyticsModels.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import Foundation
import CoreData

// MARK: - Analytics Data Models

struct WorkoutAnalytics {
    let totalWorkouts: Int
    let totalVolume: Double
    let totalSets: Int
    let totalReps: Int
    let totalDuration: TimeInterval
    let averageWorkoutDuration: TimeInterval
    let workoutsThisWeek: Int
    let workoutsThisMonth: Int
    let currentStreak: Int
    let longestStreak: Int
    let favoriteExercises: [(exercise: Exercise, count: Int)]
    let muscleGroupDistribution: [(muscleGroup: String, percentage: Double)]
}

struct ExerciseAnalytics {
    let exercise: Exercise
    let totalSets: Int
    let totalReps: Int
    let totalVolume: Double
    let maxWeight: Double
    let averageWeight: Double
    let averageReps: Double
    let lastPerformed: Date?
    let performanceHistory: [ExercisePerformance]
    let personalRecords: PersonalRecords
}

struct ExercisePerformance {
    let date: Date
    let maxWeight: Double
    let totalVolume: Double
    let totalSets: Int
    let averageReps: Double
}

struct PersonalRecords {
    let maxWeight: Double
    let maxWeightDate: Date?
    let maxVolume: Double
    let maxVolumeDate: Date?
    let maxReps: Int
    let maxRepsDate: Date?
}

struct WorkoutStreak {
    let currentStreak: Int
    let longestStreak: Int
    let lastWorkoutDate: Date?
    let streakStartDate: Date?
}

struct ProgressData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let type: ProgressType
    
    enum ProgressType {
        case weight
        case volume
        case reps
        case duration
    }
}

struct MuscleGroupStats {
    let muscleGroup: String
    let totalSets: Int
    let totalVolume: Double
    let lastTrained: Date?
    let frequency: Double // workouts per week
    let exercises: [Exercise]
}

// MARK: - Analytics Service

class AnalyticsService {
    private let context: NSManagedObjectContext
    private let calendar = Calendar.current
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Workout Analytics
    
    func getWorkoutAnalytics(from startDate: Date? = nil, to endDate: Date? = nil) throws -> WorkoutAnalytics {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        
        if let startDate = startDate, let endDate = endDate {
            request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as CVarArg, endDate as CVarArg)
        }
        
        let workouts = try context.fetch(request)
        
        // Calculate basic stats
        let totalWorkouts = workouts.count
        let totalDuration = workouts.reduce(0) { $0 + TimeInterval($1.duration) }
        let averageDuration = totalWorkouts > 0 ? totalDuration / Double(totalWorkouts) : 0
        
        // Calculate volume and sets
        var totalVolume: Double = 0
        var totalSets = 0
        var totalReps = 0
        var exerciseCounts: [Exercise: Int] = [:]
        var muscleGroupSets: [String: Int] = [:]
        
        for workout in workouts {
            for workoutExercise in workout.workoutExercisesArray {
                if let exercise = workoutExercise.exercise {
                    exerciseCounts[exercise, default: 0] += 1
                    
                    // Count muscle groups
                    for muscleGroup in exercise.muscleGroupsArray {
                        muscleGroupSets[muscleGroup, default: 0] += workoutExercise.setsArray.count
                    }
                }
                
                for set in workoutExercise.setsArray where set.completed {
                    totalSets += 1
                    totalReps += Int(set.reps)
                    totalVolume += Double(set.weight) * Double(set.reps)
                }
            }
        }
        
        // Calculate this week/month
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let workoutsThisWeek = workouts.filter { ($0.date ?? Date()) >= weekStart }.count
        let workoutsThisMonth = workouts.filter { ($0.date ?? Date()) >= monthStart }.count
        
        // Calculate streaks
        let streak = calculateWorkoutStreak()
        
        // Get favorite exercises
        let favoriteExercises = exerciseCounts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { ($0.key, $0.value) }
        
        // Calculate muscle group distribution
        let totalMuscleGroupSets = muscleGroupSets.values.reduce(0, +)
        let muscleGroupDistribution = muscleGroupSets
            .map { (muscleGroup: $0.key, percentage: Double($0.value) / Double(totalMuscleGroupSets) * 100) }
            .sorted { $0.percentage > $1.percentage }
        
        return WorkoutAnalytics(
            totalWorkouts: totalWorkouts,
            totalVolume: totalVolume,
            totalSets: totalSets,
            totalReps: totalReps,
            totalDuration: totalDuration,
            averageWorkoutDuration: averageDuration,
            workoutsThisWeek: workoutsThisWeek,
            workoutsThisMonth: workoutsThisMonth,
            currentStreak: streak.currentStreak,
            longestStreak: streak.longestStreak,
            favoriteExercises: favoriteExercises,
            muscleGroupDistribution: muscleGroupDistribution
        )
    }
    
    // MARK: - Exercise Analytics
    
    func getExerciseAnalytics(for exercise: Exercise, from startDate: Date? = nil) throws -> ExerciseAnalytics {
        let request: NSFetchRequest<WorkoutExercise> = WorkoutExercise.fetchRequest()
        request.predicate = NSPredicate(format: "exercise == %@", exercise)
        
        if let startDate = startDate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                request.predicate!,
                NSPredicate(format: "workout.date >= %@", startDate as CVarArg)
            ])
        }
        
        let workoutExercises = try context.fetch(request)
        
        var totalSets = 0
        var totalReps = 0
        var totalVolume: Double = 0
        var maxWeight: Double = 0
        var weights: [Double] = []
        var reps: [Double] = []
        var performanceByDate: [Date: ExercisePerformance] = [:]
        
        for workoutExercise in workoutExercises {
            guard let workoutDate = workoutExercise.workout?.date else { continue }
            let date = calendar.startOfDay(for: workoutDate)
            
            var dateMaxWeight: Double = 0
            var dateTotalVolume: Double = 0
            var dateTotalSets = 0
            var dateTotalReps = 0
            
            for set in workoutExercise.setsArray where set.completed {
                totalSets += 1
                totalReps += Int(set.reps)
                let volume = Double(set.weight) * Double(set.reps)
                totalVolume += volume
                dateTotalVolume += volume
                dateTotalSets += 1
                dateTotalReps += Int(set.reps)
                
                if set.weight > maxWeight {
                    maxWeight = set.weight
                }
                if set.weight > dateMaxWeight {
                    dateMaxWeight = set.weight
                }
                
                weights.append(set.weight)
                reps.append(Double(set.reps))
            }
            
            if dateTotalSets > 0 {
                performanceByDate[date] = ExercisePerformance(
                    date: date,
                    maxWeight: dateMaxWeight,
                    totalVolume: dateTotalVolume,
                    totalSets: dateTotalSets,
                    averageReps: Double(dateTotalReps) / Double(dateTotalSets)
                )
            }
        }
        
        let averageWeight = weights.isEmpty ? 0 : weights.reduce(0, +) / Double(weights.count)
        let averageReps = reps.isEmpty ? 0 : reps.reduce(0, +) / Double(reps.count)
        
        // Get performance history sorted by date
        let performanceHistory = performanceByDate.values.sorted { $0.date < $1.date }
        
        // Calculate personal records
        let personalRecords = calculatePersonalRecords(for: exercise)
        
        // Get last performed date
        let lastPerformed = workoutExercises
            .compactMap { $0.workout?.date }
            .max()
        
        return ExerciseAnalytics(
            exercise: exercise,
            totalSets: totalSets,
            totalReps: totalReps,
            totalVolume: totalVolume,
            maxWeight: maxWeight,
            averageWeight: averageWeight,
            averageReps: averageReps,
            lastPerformed: lastPerformed,
            performanceHistory: performanceHistory,
            personalRecords: personalRecords
        )
    }
    
    // MARK: - Progress Tracking
    
    func getProgressData(for exercise: Exercise, type: ProgressData.ProgressType, days: Int = 30) throws -> [ProgressData] {
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        
        let analytics = try getExerciseAnalytics(for: exercise, from: startDate)
        
        return analytics.performanceHistory.map { performance in
            let value: Double
            switch type {
            case .weight:
                value = performance.maxWeight
            case .volume:
                value = performance.totalVolume
            case .reps:
                value = performance.averageReps
            case .duration:
                value = 0 // Not applicable for exercise
            }
            
            return ProgressData(date: performance.date, value: value, type: type)
        }
    }
    
    // MARK: - Muscle Group Analysis
    
    func getMuscleGroupStats() throws -> [MuscleGroupStats] {
        let request: NSFetchRequest<WorkoutExercise> = WorkoutExercise.fetchRequest()
        let workoutExercises = try context.fetch(request)
        
        var muscleGroupData: [String: (sets: Int, volume: Double, lastDate: Date?, exercises: Set<Exercise>)] = [:]
        
        for workoutExercise in workoutExercises {
            guard let exercise = workoutExercise.exercise,
                  let workoutDate = workoutExercise.workout?.date else { continue }
            
            for muscleGroup in exercise.muscleGroupsArray {
                var data = muscleGroupData[muscleGroup] ?? (sets: 0, volume: 0, lastDate: nil, exercises: Set<Exercise>())
                
                for set in workoutExercise.setsArray where set.completed {
                    data.sets += 1
                    data.volume += Double(set.weight) * Double(set.reps)
                }
                
                if data.lastDate == nil || workoutDate > data.lastDate! {
                    data.lastDate = workoutDate
                }
                
                data.exercises.insert(exercise)
                muscleGroupData[muscleGroup] = data
            }
        }
        
        // Calculate frequency
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        
        return muscleGroupData.map { muscleGroup, data in
            // Count workouts in last 30 days
            let recentWorkoutsRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
            recentWorkoutsRequest.predicate = NSPredicate(format: "date >= %@", thirtyDaysAgo as CVarArg)
            
            let recentWorkouts = (try? context.fetch(recentWorkoutsRequest)) ?? []
            var workoutCount = 0
            
            for workout in recentWorkouts {
                let hasThisMuscleGroup = workout.workoutExercisesArray.contains { workoutExercise in
                    workoutExercise.exercise?.muscleGroupsArray.contains(muscleGroup) ?? false
                }
                if hasThisMuscleGroup {
                    workoutCount += 1
                }
            }
            
            let frequency = Double(workoutCount) / 4.3 // Average weeks in a month
            
            return MuscleGroupStats(
                muscleGroup: muscleGroup,
                totalSets: data.sets,
                totalVolume: data.volume,
                lastTrained: data.lastDate,
                frequency: frequency,
                exercises: Array(data.exercises)
            )
        }.sorted { $0.totalSets > $1.totalSets }
    }
    
    // MARK: - Helper Methods
    
    private func calculateWorkoutStreak() -> WorkoutStreak {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.date, ascending: false)]
        
        guard let workouts = try? context.fetch(request),
              !workouts.isEmpty else {
            return WorkoutStreak(currentStreak: 0, longestStreak: 0, lastWorkoutDate: nil, streakStartDate: nil)
        }
        
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 1
        var lastDate = workouts[0].date ?? Date()
        var streakStartDate = lastDate
        
        for i in 1..<workouts.count {
            guard let workoutDate = workouts[i].date else { continue }
            
            let daysBetween = calendar.dateComponents([.day], from: workoutDate, to: lastDate).day ?? 0
            
            if daysBetween == 1 {
                tempStreak += 1
                streakStartDate = workoutDate
            } else if daysBetween > 1 {
                longestStreak = max(longestStreak, tempStreak)
                tempStreak = 1
                streakStartDate = lastDate
            }
            
            lastDate = workoutDate
        }
        
        longestStreak = max(longestStreak, tempStreak)
        
        // Check if current streak is active
        if let mostRecentWorkout = workouts.first?.date {
            let daysSinceLastWorkout = calendar.dateComponents([.day], from: mostRecentWorkout, to: Date()).day ?? 0
            currentStreak = daysSinceLastWorkout <= 1 ? tempStreak : 0
        }
        
        return WorkoutStreak(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastWorkoutDate: workouts.first?.date,
            streakStartDate: currentStreak > 0 ? streakStartDate : nil
        )
    }
    
    private func calculatePersonalRecords(for exercise: Exercise) -> PersonalRecords {
        let request: NSFetchRequest<WorkoutSet> = WorkoutSet.fetchRequest()
        request.predicate = NSPredicate(format: "workoutExercise.exercise == %@ AND completed == YES", exercise)
        
        guard let sets = try? context.fetch(request) else {
            return PersonalRecords(
                maxWeight: 0,
                maxWeightDate: nil,
                maxVolume: 0,
                maxVolumeDate: nil,
                maxReps: 0,
                maxRepsDate: nil
            )
        }
        
        var maxWeight: Double = 0
        var maxWeightDate: Date?
        var maxVolume: Double = 0
        var maxVolumeDate: Date?
        var maxReps: Int16 = 0
        var maxRepsDate: Date?
        
        for set in sets {
            if set.weight > maxWeight {
                maxWeight = set.weight
                maxWeightDate = set.workoutExercise?.workout?.date
            }
            
            let volume = set.weight * Double(set.reps)
            if volume > maxVolume {
                maxVolume = volume
                maxVolumeDate = set.workoutExercise?.workout?.date
            }
            
            if set.reps > maxReps {
                maxReps = set.reps
                maxRepsDate = set.workoutExercise?.workout?.date
            }
        }
        
        return PersonalRecords(
            maxWeight: maxWeight,
            maxWeightDate: maxWeightDate,
            maxVolume: maxVolume,
            maxVolumeDate: maxVolumeDate,
            maxReps: Int(maxReps),
            maxRepsDate: maxRepsDate
        )
    }
}
