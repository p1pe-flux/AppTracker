//
//  StatisticsView.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import SwiftUI
import CoreData
import Charts

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: StatisticsViewModel
    @State private var selectedTimeRange: TimeRange = .month
    @State private var showingExerciseDetail: Exercise?
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: StatisticsViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.large) {
                    // Time range selector
                    timeRangeSelector
                    
                    // Overview cards
                    overviewSection
                    
                    // Workout streak
                    streakSection
                    
                    // Progress charts
                    progressChartsSection
                    
                    // Muscle group distribution
                    muscleGroupSection
                    
                    // Top exercises
                    topExercisesSection
                    
                    // Recent personal records
                    personalRecordsSection
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.exportData() }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(item: $showingExerciseDetail) { exercise in
                ExerciseDetailStatsView(exercise: exercise)
            }
            .onAppear {
                viewModel.loadAnalytics(for: selectedTimeRange)
            }
        }
    }
    
    // MARK: - Sections
    
    private var timeRangeSelector: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: selectedTimeRange) { newRange in
            viewModel.loadAnalytics(for: newRange)
        }
    }
    
    private var overviewSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.medium) {
            StatCard(
                title: "Total Workouts",
                value: "\(viewModel.analytics?.totalWorkouts ?? 0)",
                unit: nil,
                icon: "dumbbell",
                color: Theme.Colors.primary
            )
            
            StatCard(
                title: "Total Volume",
                value: formatVolume(viewModel.analytics?.totalVolume ?? 0),
                unit: UserPreferences.shared.weightUnit.rawValue,
                icon: "scalemass",
                color: Theme.Colors.shoulders
            )
            
            StatCard(
                title: "Total Sets",
                value: "\(viewModel.analytics?.totalSets ?? 0)",
                unit: nil,
                icon: "list.number",
                color: Theme.Colors.success
            )
            
            StatCard(
                title: "Avg Duration",
                value: formatDuration(viewModel.analytics?.averageWorkoutDuration ?? 0),
                unit: nil,
                icon: "clock",
                color: Theme.Colors.info
            )
        }
    }
    
    private var streakSection: some View {
        VStack(spacing: Theme.Spacing.medium) {
            HStack {
                Text("Workout Streak")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: Theme.Spacing.large) {
                StreakCard(
                    title: "Current",
                    days: viewModel.analytics?.currentStreak ?? 0,
                    isActive: true
                )
                
                StreakCard(
                    title: "Longest",
                    days: viewModel.analytics?.longestStreak ?? 0,
                    isActive: false
                )
            }
        }
    }
    
    @ViewBuilder
    private var progressChartsSection: some View {
        if !viewModel.volumeProgress.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                Text("Volume Progress")
                    .font(.headline)
                
                Chart(viewModel.volumeProgress) { data in
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Volume", data.value)
                    )
                    .foregroundStyle(Theme.Gradients.primary)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", data.date),
                        y: .value("Volume", data.value)
                    )
                    .foregroundStyle(Theme.Gradients.primary.opacity(0.3))
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let volume = value.as(Double.self) {
                                Text(formatVolume(volume))
                            }
                        }
                        AxisGridLine()
                    }
                }
            }
            .cardStyle()
        }
    }
    
    @ViewBuilder
    private var muscleGroupSection: some View {
        if let distribution = viewModel.analytics?.muscleGroupDistribution,
           !distribution.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                Text("Muscle Group Distribution")
                    .font(.headline)
                
                Chart(distribution.prefix(8), id: \.muscleGroup) { item in
                    SectorMark(
                        angle: .value("Percentage", item.percentage),
                        innerRadius: .ratio(0.5)
                    )
                    .foregroundStyle(by: .value("Muscle", item.muscleGroup))
                    .annotation(position: .overlay) {
                        if item.percentage > 5 {
                            Text("\(Int(item.percentage))%")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                .frame(height: 250)
                
                // Legend
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: Theme.Spacing.small) {
                    ForEach(distribution.prefix(8), id: \.muscleGroup) { item in
                        HStack {
                            Circle()
                                .fill(muscleGroupColor(item.muscleGroup))
                                .frame(width: 12, height: 12)
                            
                            Text(item.muscleGroup)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(Int(item.percentage))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .cardStyle()
        }
    }
    
    @ViewBuilder
    private var topExercisesSection: some View {
        if let favorites = viewModel.analytics?.favoriteExercises,
           !favorites.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                HStack {
                    Text("Top Exercises")
                        .font(.headline)
                    Spacer()
                    Text("Times performed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ForEach(favorites, id: \.exercise.id) { item in
                    Button(action: { showingExerciseDetail = item.exercise }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.exercise.wrappedName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text(item.exercise.wrappedCategory)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(item.count)")
                                .font(.headline)
                                .foregroundColor(Theme.Colors.primary)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, Theme.Spacing.small)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if item.exercise != favorites.last?.exercise {
                        Divider()
                    }
                }
            }
            .cardStyle()
        }
    }
    
    @ViewBuilder
    private var personalRecordsSection: some View {
        if !viewModel.recentPRs.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                Text("Recent Personal Records")
                    .font(.headline)
                
                ForEach(viewModel.recentPRs) { pr in
                    PersonalRecordRow(record: pr)
                    
                    if pr != viewModel.recentPRs.last {
                        Divider()
                    }
                }
            }
            .cardStyle()
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
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
    
    private func muscleGroupColor(_ muscleGroup: String) -> Color {
        // Map muscle groups to exercise categories for consistent colors
        if let muscleGroupEnum = MuscleGroup(rawValue: muscleGroup) {
            return muscleGroupEnum.category.color
        }
        return Theme.Colors.other
    }
}

// MARK: - Supporting Views

struct StreakCard: View {
    let title: String
    let days: Int
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(isActive ? Theme.Colors.cardio : .secondary)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("\(days)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(isActive ? Theme.Colors.primary : .secondary)
            
            Text(days == 1 ? "day" : "days")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .stroke(isActive ? Theme.Colors.primary.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
    }
}

struct PersonalRecordRow: View {
    let record: PersonalRecord
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "trophy.fill")
                .font(.title3)
                .foregroundColor(Theme.Colors.warning)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.exercise.wrappedName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(record.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(record.formattedValue)
                    .font(.headline)
                    .foregroundColor(Theme.Colors.primary)
                
                Text(record.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - View Model

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var analytics: WorkoutAnalytics?
    @Published var volumeProgress: [ProgressData] = []
    @Published var recentPRs: [PersonalRecord] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let analyticsService: AnalyticsService
    
    init(context: NSManagedObjectContext) {
        self.analyticsService = AnalyticsService(context: context)
    }
    
    func loadAnalytics(for timeRange: TimeRange) {
        isLoading = true
        
        Task {
            do {
                let (startDate, endDate) = timeRange.dateRange
                analytics = try analyticsService.getWorkoutAnalytics(from: startDate, to: endDate)
                
                // Load volume progress
                loadVolumeProgress(from: startDate, to: endDate)
                
                // Load recent PRs
                loadRecentPRs()
                
                isLoading = false
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func loadVolumeProgress(from startDate: Date, to endDate: Date) {
        // This would aggregate volume data by day
        // For now, using mock data
        volumeProgress = []
        
        let calendar = Calendar.current
        var date = startDate
        
        while date <= endDate {
            let volume = Double.random(in: 1000...5000)
            volumeProgress.append(ProgressData(date: date, value: volume, type: .volume))
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
    }
    
    private func loadRecentPRs() {
        // This would fetch actual PR data
        // For now, using mock data
        recentPRs = []
    }
    
    func exportData() {
        // Export functionality
    }
}

// MARK: - Models

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case year = "Year"
    case all = "All Time"
    
    var title: String { rawValue }
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            let start = calendar.date(byAdding: .day, value: -7, to: now)!
            return (start, now)
        case .month:
            let start = calendar.date(byAdding: .month, value: -1, to: now)!
            return (start, now)
        case .threeMonths:
            let start = calendar.date(byAdding: .month, value: -3, to: now)!
            return (start, now)
        case .year:
            let start = calendar.date(byAdding: .year, value: -1, to: now)!
            return (start, now)
        case .all:
            let start = calendar.date(byAdding: .year, value: -10, to: now)!
            return (start, now)
        }
    }
}

struct PersonalRecord: Identifiable, Equatable {
    let id = UUID()
    let exercise: Exercise
    let type: PRType
    let value: Double
    let date: Date
    
    enum PRType: Equatable {
        case weight
        case volume
        case reps
    }
    
    static func == (lhs: PersonalRecord, rhs: PersonalRecord) -> Bool {
        lhs.id == rhs.id &&
        lhs.exercise == rhs.exercise &&
        lhs.type == rhs.type &&
        lhs.value == rhs.value &&
        lhs.date == rhs.date
    }
    
    var description: String {
        switch type {
        case .weight: return "Max Weight"
        case .volume: return "Max Volume"
        case .reps: return "Max Reps"
        }
    }
    
    var formattedValue: String {
        switch type {
        case .weight:
            return UserPreferences.shared.formatWeight(value)
        case .volume:
            return UserPreferences.shared.formatWeight(value)
        case .reps:
            return "\(Int(value)) reps"
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
