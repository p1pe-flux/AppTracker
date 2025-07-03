//
//  WorkoutListView.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import SwiftUI
import CoreData

struct WorkoutListView: View {
    @StateObject private var viewModel: WorkoutViewModel
    @State private var showingCreateWorkout = false
    @State private var selectedWorkout: Workout?
    @State private var showingActiveWorkout = false
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: WorkoutViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Today's workouts section
                if !viewModel.todayWorkouts.isEmpty {
                    todaySection
                }
                
                // All workouts list
                if viewModel.isLoading {
                    ProgressView("Loading workouts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.workouts.isEmpty {
                    emptyState
                } else {
                    workoutsList
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateWorkout = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateWorkout) {
                CreateWorkoutView(viewModel: viewModel)
            }
            .sheet(item: $selectedWorkout) { workout in
                NavigationView {
                    ActiveWorkoutView(workout: workout)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.showError = false }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.todayWorkouts) { workout in
                        TodayWorkoutCard(workout: workout) {
                            selectedWorkout = workout
                        }
                    }
                    
                    // Quick start button
                    Button(action: { showingCreateWorkout = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.accentColor)
                            
                            Text("Quick Start")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(width: 120, height: 100)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
            
            Divider()
        }
    }
    
    private var workoutsList: some View {
        List {
            ForEach(groupedWorkouts, id: \.key) { section in
                Section(header: Text(section.key)) {
                    ForEach(section.value) { workout in
                        WorkoutRowView(workout: workout)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedWorkout = workout
                            }
                    }
                    .onDelete { offsets in
                        deleteWorkouts(from: section.value, at: offsets)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No workouts yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the + button to create your first workout")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create Workout") {
                showingCreateWorkout = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private var groupedWorkouts: [(key: String, value: [Workout])] {
        let grouped = Dictionary(grouping: viewModel.workouts) { workout -> String in
            let date = workout.date ?? Date()
            if Calendar.current.isDateInToday(date) {
                return "Today"
            } else if Calendar.current.isDateInYesterday(date) {
                return "Yesterday"
            } else if let weekday = Calendar.current.dateComponents([.weekday], from: date).weekday,
                      let daysAgo = Calendar.current.dateComponents([.day], from: date, to: Date()).day,
                      daysAgo <= 7 {
                return Calendar.current.weekdaySymbols[weekday - 1]
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d, yyyy"
                return formatter.string(from: date)
            }
        }
        
        return grouped.sorted { first, second in
            // Sort by most recent first
            guard let firstDate = first.value.first?.date,
                  let secondDate = second.value.first?.date else {
                return false
            }
            return firstDate > secondDate
        }
    }
    
    private func deleteWorkouts(from workouts: [Workout], at offsets: IndexSet) {
        Task {
            for index in offsets {
                if index < workouts.count {
                    await viewModel.deleteWorkout(workouts[index])
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct TodayWorkoutCard: View {
    let workout: Workout
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(workout.wrappedName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                if workout.isCompleted {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if workout.totalSets > 0 {
                    ProgressView(value: workout.progress)
                        .tint(.accentColor)
                    
                    Text("\(workout.completedSets)/\(workout.totalSets) sets")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Label("Not started", systemImage: "play.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(width: 140, height: 100)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkoutRowView: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.wrappedName)
                    .font(.headline)
                
                HStack {
                    if workout.workoutExercisesArray.count > 0 {
                        Label("\(workout.workoutExercisesArray.count) exercises", systemImage: "figure.strengthtraining.traditional")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if workout.duration > 0 {
                        Label(workout.formattedDuration, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if workout.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if workout.completedSets > 0 {
                CircularProgressView(progress: workout.progress)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 3)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, lineWidth: 3)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 8))
                .fontWeight(.bold)
        }
    }
}

// MARK: - Preview

struct WorkoutListView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutListView(context: PersistenceController.preview.container.viewContext)
    }
}
