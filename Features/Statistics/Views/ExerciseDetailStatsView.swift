//
//  ExerciseDetailStatsView.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import SwiftUI
import CoreData
import Charts

struct ExerciseDetailStatsView: View {
    let exercise: Exercise
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ExerciseStatsViewModel
    @State private var selectedMetric: MetricType = .weight
    @State private var selectedTimeRange: TimeRange = .month
    
    init(exercise: Exercise) {
        self.exercise = exercise
        _viewModel = StateObject(wrappedValue: ExerciseStatsViewModel(
            exercise: exercise,
            context: exercise.managedObjectContext ?? PersistenceController.shared.container.viewContext
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.large) {
                    // Exercise header
                    exerciseHeader
                    
                    // Personal records
                    personalRecordsSection
                    
                    // Time range selector
                    timeRangeSelector
                    
                    // Progress chart
                    progressChart
                    
                    // Stats overview
                    statsOverview
                    
                    // Recent performances
                    recentPerformances
                    
                    // Muscle groups
                    muscleGroupsSection
                }
                .padding()
            }
            .navigationTitle("Exercise Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.loadStats(for: selectedTimeRange)
            }
        }
    }
    
    // MARK: - Sections
    
    private var exerciseHeader: some View {
        VStack(spacing: Theme.Spacing.small) {
            HStack {
                Image(systemName: ExerciseCategory(rawValue: exercise.wrappedCategory)?.systemImage ?? "questionmark.circle")
                    .font(.largeTitle)
                    .foregroundColor(ExerciseCategory(rawValue: exercise.wrappedCategory)?.color ?? Theme.Colors.other)
                
                VStack(alignment: .leading) {
                    Text(exercise.wrappedName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(exercise.wrappedCategory)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if let lastPerformed = viewModel.analytics?.lastPerformed {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Last performed: \(lastPerformed.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Personal Records")
                .font(.headline)
            
            HStack(spacing: Theme.Spacing.medium) {
                PRCard(
                    title: "Max Weight",
                    value: UserPreferences.shared.formatWeight(viewModel.analytics?.personalRecords.maxWeight ?? 0),
                    date: viewModel.analytics?.personalRecords.maxWeightDate,
                    icon: "scalemass",
                    color: Theme.Colors.primary
                )
                
                PRCard(
                    title: "Max Volume",
                    value: UserPreferences.shared.formatWeight(viewModel.analytics?.personalRecords.maxVolume ?? 0),
                    date: viewModel.analytics?.personalRecords.maxVolumeDate,
                    icon: "chart.bar.fill",
                    color: Theme.Colors.shoulders
                )
                
                PRCard(
                    title: "Max Reps",
                    value: "\(viewModel.analytics?.personalRecords.maxReps ?? 0)",
                    date: viewModel.analytics?.personalRecords.maxRepsDate,
                    icon: "number",
                    color: Theme.Colors.success
                )
            }
        }
    }
    
    private var timeRangeSelector: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach([TimeRange.week, TimeRange.month, TimeRange.threeMonths], id: \.self) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: selectedTimeRange) { _, newRange in
            viewModel.loadStats(for: newRange)
        }
    }
    
    @ViewBuilder
    private var progressChart: some View {
        if !viewModel.progressData.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                HStack {
                    Text("Progress")
                        .font(.headline)
                    
                    Spacer()
                    
                    Picker("Metric", selection: $selectedMetric) {
                        ForEach(MetricType.allCases, id: \.self) { metric in
                            Text(metric.title).tag(metric)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .font(.caption)
                }
                
                Chart(viewModel.progressData.filter { $0.type == selectedMetric.progressType }) { data in
                    switch selectedMetric {
                    case .weight, .volume:
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value(selectedMetric.title, data.value)
                        )
                        .foregroundStyle(Theme.Colors.primary)
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Date", data.date),
                            y: .value(selectedMetric.title, data.value)
                        )
                        .foregroundStyle(Theme.Colors.primary)
                        
                    case .reps:
                        BarMark(
                            x: .value("Date", data.date),
                            y: .value(selectedMetric.title, data.value)
                        )
                        .foregroundStyle(Theme.Gradients.primary)
                    }
                }
                .frame(height: 250)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text(formatChartValue(val))
                            }
                        }
                        AxisGridLine()
                    }
                }
            }
            .cardStyle()
        }
    }
    
    private var statsOverview: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.medium) {
            StatCard(
                title: "Total Sets",
                value: "\(viewModel.analytics?.totalSets ?? 0)",
                unit: nil,
                icon: "list.bullet",
                color: Theme.Colors.info
            )
            
            StatCard(
                title: "Total Reps",
                value: "\(viewModel.analytics?.totalReps ?? 0)",
                unit: nil,
                icon: "repeat",
                color: Theme.Colors.success
            )
            
            StatCard(
                title: "Avg Weight",
                value: formatWeight(viewModel.analytics?.averageWeight ?? 0),
                unit: UserPreferences.shared.weightUnit.rawValue,
                icon: "scalemass",
                color: Theme.Colors.primary
            )
            
            StatCard(
                title: "Avg Reps",
                value: String(format: "%.1f", viewModel.analytics?.averageReps ?? 0),
                unit: "per set",
                icon: "chart.line.uptrend.xyaxis",
                color: Theme.Colors.shoulders
            )
        }
    }
    
    @ViewBuilder
    private var recentPerformances: some View {
        if let performances = viewModel.analytics?.performanceHistory.suffix(5).reversed(),
           !performances.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                Text("Recent Performances")
                    .font(.headline)
                
                VStack(spacing: Theme.Spacing.small) {
                    ForEach(Array(performances), id: \.date) { performance in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(performance.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                HStack {
                                    Text("\(performance.totalSets) sets")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    
                                    Text("Avg \(Int(performance.averageReps)) reps")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(UserPreferences.shared.formatWeight(performance.maxWeight))
                                    .font(.headline)
                                    .foregroundColor(Theme.Colors.primary)
                                
                                Text("Max weight")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.xSmall)
                        
                        if performance.date != performances.last?.date {
                            Divider()
                        }
                    }
                }
            }
            .cardStyle()
        }
    }
    
    private var muscleGroupsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Muscle Groups")
                .font(.headline)
            
            if exercise.muscleGroupsArray.isEmpty {
                Text("No muscle groups specified")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: Theme.Spacing.small) {
                    ForEach(exercise.muscleGroupsArray, id: \.self) { muscleGroup in
                        HStack(spacing: 4) {
                            if let muscle = MuscleGroup(rawValue: muscleGroup) {
                                Circle()
                                    .fill(muscle.category.color)
                                    .frame(width: 8, height: 8)
                            }
                            
                            Text(muscleGroup)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(UIColor.tertiarySystemBackground))
                        )
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Helper Methods
    
    private func formatChartValue(_ value: Double) -> String {
        switch selectedMetric {
        case .weight, .volume:
            return formatWeight(value)
        case .reps:
            return "\(Int(value))"
        }
    }
    
    private func formatWeight(_ weight: Double) -> String {
        let converted = UserPreferences.shared.convertWeight(weight)
        if converted.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", converted)
        } else {
            return String(format: "%.1f", converted)
        }
    }
}

// MARK: - Supporting Views

struct PRCard: View {
    let title: String
    let value: String
    let date: Date?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            if let date = date {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - View Model

@MainActor
class ExerciseStatsViewModel: ObservableObject {
    @Published var analytics: ExerciseAnalytics?
    @Published var progressData: [ProgressData] = []
    @Published var isLoading = false
    
    private let exercise: Exercise
    private let analyticsService: AnalyticsService
    
    init(exercise: Exercise, context: NSManagedObjectContext) {
        self.exercise = exercise
        self.analyticsService = AnalyticsService(context: context)
    }
    
    func loadStats(for timeRange: TimeRange) {
        isLoading = true
        
        Task {
            do {
                let (startDate, _) = timeRange.dateRange
                analytics = try analyticsService.getExerciseAnalytics(for: exercise, from: startDate)
                
                // Load progress data for all metrics
                progressData = []
                for metric in MetricType.allCases {
                    let data = try analyticsService.getProgressData(
                        for: exercise,
                        type: metric.progressType,
                        days: timeRange.days
                    )
                    progressData.append(contentsOf: data)
                }
                
                isLoading = false
            } catch {
                print("Error loading exercise stats: \(error)")
                isLoading = false
            }
        }
    }
}

// MARK: - Models

enum MetricType: String, CaseIterable {
    case weight = "Weight"
    case volume = "Volume"
    case reps = "Reps"
    
    var title: String { rawValue }
    
    var progressType: ProgressData.ProgressType {
        switch self {
        case .weight: return .weight
        case .volume: return .volume
        case .reps: return .reps
        }
    }
}

extension TimeRange {
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        case .all: return 3650
        }
    }
}
