//
//  WorkoutDetailCard.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import SwiftUI
import CoreData

struct WorkoutDetailCard: View {
    let workout: Workout
    @State private var isExpanded = false
    @State private var showingEditView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            // Header
            workoutHeader
            
            // Stats summary
            statsSummary
            
            // Exercises section
            if isExpanded {
                exercisesSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Notes section
            if isExpanded && !workout.wrappedNotes.isEmpty {
                notesSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cardStyle()
        .sheet(isPresented: $showingEditView) {
            // Edit workout view would go here
        }
    }
    
    // MARK: - Sections
    
    private var workoutHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.wrappedName)
                    .font(.headline)
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(workout.date?.formatted(date: .abbreviated, time: .shortened) ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: Theme.Spacing.small) {
                if workout.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.success)
                } else if workout.totalSets > 0 {
                    WorkoutProgressIndicator(progress: workout.progress, size: 30)
                }
                
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var statsSummary: some View {
        HStack {
            StatBadge(
                value: "\(workout.workoutExercisesArray.count)",
                label: "Exercises",
                color: Theme.Colors.primary
            )
            
            Spacer()
            
            StatBadge(
                value: "\(workout.totalSets)",
                label: "Sets",
                color: Theme.Colors.shoulders
            )
            
            Spacer()
            
            StatBadge(
                value: formatVolume(workout.totalVolume),
                label: "Volume",
                color: Theme.Colors.success
            )
            
            Spacer()
            
            if workout.duration > 0 {
                StatBadge(
                    value: workout.formattedDuration,
                    label: "Duration",
                    color: Theme.Colors.info
                )
            }
        }
    }
    
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("Exercises")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            ForEach(workout.workoutExercisesArray) { workoutExercise in
                ExerciseSummaryRow(workoutExercise: workoutExercise)
                
                if workoutExercise != workout.workoutExercisesArray.last {
                    Divider()
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
            Text("Notes")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text(workout.wrappedNotes)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatVolume(_ volume: Double) -> String {
        let converted = UserPreferences.shared.convertWeight(volume)
        if converted >= 1000 {
            return String(format: "%.1fk", converted / 1000)
        }
        return String(format: "%.0f", converted)
    }
}

// MARK: - Supporting Views

struct StatBadge: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct ExerciseSummaryRow: View {
    let workoutExercise: WorkoutExercise
    @State private var showingDetail = false
    
    private var bestSet: WorkoutSet? {
        workoutExercise.setsArray
            .filter { $0.completed }
            .max { ($0.weight * Double($0.reps)) < ($1.weight * Double($1.reps)) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
            HStack {
                Text(workoutExercise.exercise?.wrappedName ?? "Unknown Exercise")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if showingDetail {
                    Button(action: { showingDetail.toggle() }) {
                        Image(systemName: "chevron.up")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            HStack {
                Text("\(workoutExercise.completedSetsCount)/\(workoutExercise.setsArray.count) sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let bestSet = bestSet {
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("Best: \(UserPreferences.shared.formatWeight(bestSet.weight)) × \(bestSet.reps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !showingDetail {
                    Button(action: { showingDetail.toggle() }) {
                        Text("Details")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
            
            if showingDetail {
                VStack(spacing: Theme.Spacing.xSmall) {
                    ForEach(workoutExercise.setsArray) { set in
                        SetSummaryRow(set: set)
                    }
                }
                .padding(.top, Theme.Spacing.xSmall)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct SetSummaryRow: View {
    let set: WorkoutSet
    
    var body: some View {
        HStack {
            Text("Set \(set.setNumber)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            
            HStack(spacing: 4) {
                Text(UserPreferences.shared.formatWeight(set.weight))
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("×")
                    .foregroundColor(.secondary)
                
                Text("\(set.reps)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            if set.completed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.success)
            } else {
                Image(systemName: "circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Full Workout Detail View

struct FullWorkoutDetailView: View {
    let workout: Workout
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.large) {
                    // Header info
                    headerSection
                    
                    // Overall stats
                    overallStatsSection
                    
                    // Exercises breakdown
                    exercisesBreakdown
                    
                    // Performance metrics
                    performanceMetrics
                    
                    // Notes
                    if !workout.wrappedNotes.isEmpty {
                        notesDetailSection
                    }
                }
                .padding()
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [generateWorkoutSummary()])
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(workout.wrappedName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Label(workout.formattedDate, systemImage: "calendar")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if workout.duration > 0 {
                            Label(workout.formattedDuration, systemImage: "clock")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                if workout.isCompleted {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(Theme.Colors.success)
                        
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.success)
                    }
                } else {
                    VStack {
                        WorkoutProgressIndicator(progress: workout.progress, size: 50)
                        
                        Text("\(Int(workout.progress * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .cardStyle()
    }
    
    private var overallStatsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Overall Stats")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.medium) {
                StatCard(
                    title: "Exercises",
                    value: "\(workout.workoutExercisesArray.count)",
                    unit: nil,
                    icon: "figure.strengthtraining.traditional",
                    color: Theme.Colors.primary
                )
                
                StatCard(
                    title: "Total Sets",
                    value: "\(workout.totalSets)",
                    unit: nil,
                    icon: "list.number",
                    color: Theme.Colors.shoulders
                )
                
                StatCard(
                    title: "Completed Sets",
                    value: "\(workout.completedSets)",
                    unit: nil,
                    icon: "checkmark.circle",
                    color: Theme.Colors.success
                )
                
                StatCard(
                    title: "Total Volume",
                    value: formatVolume(workout.totalVolume),
                    unit: UserPreferences.shared.weightUnit.rawValue,
                    icon: "scalemass",
                    color: Theme.Colors.info
                )
            }
        }
    }
    
    private var exercisesBreakdown: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Exercises Breakdown")
                .font(.headline)
            
            ForEach(workout.workoutExercisesArray) { workoutExercise in
                ExerciseBreakdownCard(workoutExercise: workoutExercise)
            }
        }
    }
    
    private var performanceMetrics: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Performance Metrics")
                .font(.headline)
            
            // Volume by muscle group
            if let muscleGroupVolumes = calculateMuscleGroupVolumes() {
                VolumeByMuscleGroupChart(data: muscleGroupVolumes)
                    .frame(height: 200)
                    .cardStyle()
            }
        }
    }
    
    private var notesDetailSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("Notes")
                .font(.headline)
            
            Text(workout.wrappedNotes)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .fill(Color(UIColor.tertiarySystemBackground))
                )
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatVolume(_ volume: Double) -> String {
        let converted = UserPreferences.shared.convertWeight(volume)
        return String(format: "%.0f", converted)
    }
    
    private func calculateMuscleGroupVolumes() -> [(muscleGroup: String, volume: Double)]? {
        var volumes: [String: Double] = [:]
        
        for workoutExercise in workout.workoutExercisesArray {
            guard let exercise = workoutExercise.exercise else { continue }
            let exerciseVolume = workoutExercise.totalVolume
            
            for muscleGroup in exercise.muscleGroupsArray {
                volumes[muscleGroup, default: 0] += exerciseVolume
            }
        }
        
        return volumes.isEmpty ? nil : volumes.map { ($0.key, $0.value) }.sorted { $0.volume > $1.volume }
    }
    
    private func generateWorkoutSummary() -> String {
        var summary = "Workout Summary\n"
        summary += "================\n\n"
        summary += "Name: \(workout.wrappedName)\n"
        summary += "Date: \(workout.formattedDate)\n"
        summary += "Duration: \(workout.formattedDuration)\n\n"
        
        summary += "Exercises:\n"
        for workoutExercise in workout.workoutExercisesArray {
            if let exercise = workoutExercise.exercise {
                summary += "\n\(exercise.wrappedName):\n"
                for set in workoutExercise.setsArray {
                    summary += "  Set \(set.setNumber): \(UserPreferences.shared.formatWeight(set.weight)) × \(set.reps)"
                    summary += set.completed ? " ✓\n" : "\n"
                }
            }
        }
        
        summary += "\nTotal Volume: \(UserPreferences.shared.formatWeight(workout.totalVolume))\n"
        summary += "Total Sets: \(workout.totalSets)\n"
        
        if !workout.wrappedNotes.isEmpty {
            summary += "\nNotes: \(workout.wrappedNotes)\n"
        }
        
        return summary
    }
}

// MARK: - Exercise Breakdown Card

struct ExerciseBreakdownCard: View {
    let workoutExercise: WorkoutExercise
    @State private var isExpanded = false
    
    private var averageWeight: Double {
        let completedSets = workoutExercise.setsArray.filter { $0.completed }
        guard !completedSets.isEmpty else { return 0 }
        let totalWeight = completedSets.reduce(0) { $0 + $1.weight }
        return totalWeight / Double(completedSets.count)
    }
    
    private var averageReps: Double {
        let completedSets = workoutExercise.setsArray.filter { $0.completed }
        guard !completedSets.isEmpty else { return 0 }
        let totalReps = completedSets.reduce(0) { $0 + Int($1.reps) }
        return Double(totalReps) / Double(completedSets.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workoutExercise.exercise?.wrappedName ?? "Unknown Exercise")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Label("\(workoutExercise.completedSetsCount)/\(workoutExercise.setsArray.count) sets", systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text("Volume: \(UserPreferences.shared.formatWeight(workoutExercise.totalVolume))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: Theme.Spacing.small) {
                    // Average stats
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Avg Weight")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(UserPreferences.shared.formatWeight(averageWeight))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .center) {
                            Text("Avg Reps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f", averageReps))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Total Volume")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(UserPreferences.shared.formatWeight(workoutExercise.totalVolume))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.vertical, Theme.Spacing.xSmall)
                    
                    Divider()
                    
                    // Sets detail
                    ForEach(workoutExercise.setsArray) { set in
                        HStack {
                            Text("Set \(set.setNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .leading)
                            
                            Text("\(UserPreferences.shared.formatWeight(set.weight)) × \(set.reps)")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if set.volume > 0 {
                                Text("\(Int(set.volume)) \(UserPreferences.shared.weightUnit.rawValue)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                                .foregroundColor(set.completed ? Theme.Colors.success : .secondary)
                        }
                    }
                }
                .padding(.top, Theme.Spacing.xSmall)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
    }
}

// MARK: - Volume by Muscle Group Chart

struct VolumeByMuscleGroupChart: View {
    let data: [(muscleGroup: String, volume: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("Volume by Muscle Group")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(data, id: \.muscleGroup) { item in
                HStack {
                    Text(item.muscleGroup)
                        .font(.caption)
                        .frame(width: 100, alignment: .leading)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 20)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(muscleGroupColor(item.muscleGroup))
                                .frame(width: barWidth(for: item.volume, in: geometry.size.width), height: 20)
                        }
                    }
                    .frame(height: 20)
                    
                    Text(UserPreferences.shared.formatWeight(item.volume))
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(width: 60, alignment: .trailing)
                }
            }
        }
    }
    
    private func barWidth(for volume: Double, in totalWidth: CGFloat) -> CGFloat {
        guard let maxVolume = data.map({ $0.volume }).max(), maxVolume > 0 else { return 0 }
        return (volume / maxVolume) * totalWidth
    }
    
    private func muscleGroupColor(_ muscleGroup: String) -> Color {
        if let muscle = MuscleGroup(rawValue: muscleGroup) {
            return muscle.category.color
        }
        return Theme.Colors.other
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
