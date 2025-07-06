//
//  WorkoutCalendarView.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 4/7/25.
//

import SwiftUI
import CoreData

struct WorkoutCalendarView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: CalendarViewModel
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @State private var selectedDate = Date()
    @State private var showingDayDetail = false
    @State private var showingCreateWorkout = false
    @State private var showingDuplicateSheet = false
    @State private var selectedWorkoutToDuplicate: Workout?
    
    init(context: NSManagedObjectContext, workoutViewModel: WorkoutViewModel) {
        self.workoutViewModel = workoutViewModel
        _viewModel = StateObject(wrappedValue: CalendarViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Month navigation
                monthNavigationHeader
                
                // Calendar grid
                calendarGrid
                
                // Selected date workouts
                selectedDateSection
            }
            .navigationTitle("Workout Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingDayDetail) {
                DayDetailView(date: selectedDate, context: context)
            }
            .sheet(isPresented: $showingCreateWorkout) {
                CreateWorkoutFromCalendarView(
                    selectedDate: selectedDate,
                    viewModel: workoutViewModel // Usar el viewModel compartido
                )
            }
            .onAppear {
                viewModel.loadMonth(for: selectedDate)
            }
        }
    }
    
    // MARK: - Calendar Components
    
    private var monthNavigationHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(Theme.Colors.primary)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("\(viewModel.workoutsInMonth.count) workouts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(Theme.Colors.primary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var calendarGrid: some View {
        VStack(spacing: 0) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, Theme.Spacing.small)
            
            // Calendar days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(viewModel.calendarDays) { day in
                    CalendarDayView(
                        day: day,
                        isSelected: Calendar.current.isDate(day.date, inSameDayAs: selectedDate),
                        workouts: viewModel.workouts(for: day.date)
                    ) {
                        selectedDate = day.date
                        HapticManager.shared.selection()
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var selectedDateSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedDateString)
                        .font(.headline)
                    
                    if let workouts = viewModel.workouts(for: selectedDate), !workouts.isEmpty {
                        Text("\(workouts.count) workout\(workouts.count > 1 ? "s" : "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: Theme.Spacing.small) {
                    Button(action: { showingCreateWorkout = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Theme.Colors.primary)
                    }
                    
                    if viewModel.workouts(for: selectedDate) != nil {
                        Button("Details") {
                            showingDayDetail = true
                        }
                        .font(.subheadline)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            ScrollView {
                if let workouts = viewModel.workouts(for: selectedDate), !workouts.isEmpty {
                    VStack(spacing: Theme.Spacing.medium) {
                        ForEach(workouts) { workout in
                            WorkoutCalendarCard(workout: workout)
                                .contextMenu {
                                    Button(action: {
                                        selectedWorkoutToDuplicate = workout
                                        showingDuplicateSheet = true
                                    }) {
                                        Label("Duplicate", systemImage: "doc.on.doc")
                                    }
                                    
                                    Button(action: {
                                        duplicateToToday(workout)
                                    }) {
                                        Label("Duplicate to Today", systemImage: "calendar.badge.plus")
                                    }
                                    
                                    Button(action: {
                                        // Navigate to active workout
                                    }) {
                                        Label("Start Workout", systemImage: "play.circle")
                                    }
                                    
                                    Button(role: .destructive, action: {
                                        deleteWorkout(workout)
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    EmptyStateView(
                        icon: "calendar.badge.minus",
                        title: "No workouts",
                        message: "No workouts recorded for this date",
                        actionTitle: "Add Workout",
                        action: {
                            showingCreateWorkout = true
                        }
                    )
                    .frame(height: 200)
                }
            }
        }
        .sheet(isPresented: $showingCreateWorkout) {
            CreateWorkoutFromCalendarView(
                selectedDate: selectedDate,
                viewModel: WorkoutViewModel(context: context)
            )
        }
        .sheet(isPresented: $showingDuplicateSheet) {
            if let workout = selectedWorkoutToDuplicate {
                DuplicateWorkoutView(workout: workout)
            }
        }
    } // <- Esta llave de cierre faltaba
    
    // MARK: - Helper Methods
    
    private func duplicateToToday(_ workout: Workout) {
        let duplicationService = WorkoutDuplicationService(context: context)
        
        Task {
            do {
                _ = try duplicationService.duplicateWorkout(
                    workout,
                    toDate: Date(),
                    withName: "\(workout.wrappedName) - Today"
                )
                
                HapticManager.shared.notification(.success)
                
                // Recargar el calendario
                viewModel.loadMonth(for: viewModel.currentMonth)
            } catch {
                print("Error duplicating workout: \(error)")
            }
        }
    }
    
    private func deleteWorkout(_ workout: Workout) {
        context.delete(workout)
        do {
            try context.save()
            viewModel.loadMonth(for: viewModel.currentMonth)
            HapticManager.shared.notification(.warning)
        } catch {
            print("Error deleting workout: \(error)")
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: viewModel.currentMonth)
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: selectedDate)
    }
    
    private func previousMonth() {
        withAnimation {
            viewModel.currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: viewModel.currentMonth) ?? viewModel.currentMonth
            viewModel.loadMonth(for: viewModel.currentMonth)
        }
    }
    
    private func nextMonth() {
        withAnimation {
            viewModel.currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: viewModel.currentMonth) ?? viewModel.currentMonth
            viewModel.loadMonth(for: viewModel.currentMonth)
        }
    }
}

// MARK: - Calendar Day View

struct CalendarDayView: View {
    let day: CalendarDay
    let isSelected: Bool
    let workouts: [Workout]?
    let action: () -> Void
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }
    
    private var workoutCount: Int {
        workouts?.count ?? 0
    }
    
    private var hasCompletedWorkout: Bool {
        workouts?.contains { $0.isCompleted } ?? false
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(day.dayNumber)")
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundColor(textColor)
                
                if workoutCount > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<min(workoutCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(hasCompletedWorkout ? Theme.Colors.success : Theme.Colors.primary)
                                .frame(width: 4, height: 4)
                        }
                    }
                } else {
                    // Empty space to maintain consistent height
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(backgroundView)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!day.isInCurrentMonth)
    }
    
    private var textColor: Color {
        if !day.isInCurrentMonth {
            return Color.secondary.opacity(0.3)
        } else if isSelected || isToday {
            return hasCompletedWorkout ? .white : (isToday ? Theme.Colors.primary : .primary)
        } else {
            return .primary
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                .fill(hasCompletedWorkout ? Theme.Colors.success : Theme.Colors.primary.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .stroke(hasCompletedWorkout ? Theme.Colors.success : Theme.Colors.primary, lineWidth: 2)
                )
        } else if isToday {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                .stroke(Theme.Colors.primary, lineWidth: 1)
        } else if hasCompletedWorkout {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                .fill(Theme.Colors.success.opacity(0.1))
        }
    }
}

// MARK: - Workout Calendar Card

struct WorkoutCalendarCard: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.wrappedName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
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
                        .foregroundColor(Theme.Colors.success)
                } else if workout.totalSets > 0 {
                    WorkoutProgressIndicator(progress: workout.progress, size: 24)
                }
            }
            
            if workout.totalVolume > 0 {
                HStack {
                    Text("Volume:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(UserPreferences.shared.formatWeight(workout.totalVolume))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
    }
}

// MARK: - Day Detail View

struct DayDetailView: View {
    let date: Date
    let context: NSManagedObjectContext
    @Environment(\.dismiss) private var dismiss
    @State private var workouts: [Workout] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                if workouts.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.minus",
                        title: "No workouts",
                        message: "No workouts recorded for this date",
                        actionTitle: nil,
                        action: nil
                    )
                    .padding(.top, 100)
                } else {
                    VStack(spacing: Theme.Spacing.large) {
                        ForEach(workouts) { workout in
                            WorkoutDetailCard(workout: workout)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        deleteWorkout(workout)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(dateString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadWorkouts()
            }
        }
    }
    
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func loadWorkouts() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as CVarArg, endOfDay as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.date, ascending: true)]
        
        do {
            workouts = try context.fetch(request)
        } catch {
            print("Error loading workouts: \(error)")
        }
    }
    
    private func deleteWorkout(_ workout: Workout) {
        context.delete(workout)
        do {
            try context.save()
            loadWorkouts()
            HapticManager.shared.notification(.warning)
        } catch {
            print("Error deleting workout: \(error)")
        }
    }
}

// MARK: - View Model

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var currentMonth = Date()
    @Published var calendarDays: [CalendarDay] = []
    @Published var workoutsInMonth: [Date: [Workout]] = [:]
    
    private let context: NSManagedObjectContext
    private let calendar = Calendar.current
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func loadMonth(for date: Date) {
        // Generate calendar days
        generateCalendarDays(for: date)
        
        // Load workouts for the month
        loadWorkouts(for: date)
    }
    
    func workouts(for date: Date) -> [Workout]? {
        let startOfDay = calendar.startOfDay(for: date)
        return workoutsInMonth[startOfDay]
    }
    
    private func generateCalendarDays(for date: Date) {
        var days: [CalendarDay] = []
        
        guard let monthRange = calendar.range(of: .day, in: .month, for: date),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        
        // Add previous month's trailing days
        if firstWeekday > 0 {
            guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstOfMonth) else { return }
            let previousMonthDays = calendar.range(of: .day, in: .month, for: previousMonth)?.count ?? 30
            
            for day in (previousMonthDays - firstWeekday + 1)...previousMonthDays {
                if let date = calendar.date(byAdding: .day, value: day - previousMonthDays - 1, to: firstOfMonth) {
                    days.append(CalendarDay(date: date, dayNumber: day, isInCurrentMonth: false))
                }
            }
        }
        
        // Add current month's days
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(CalendarDay(date: date, dayNumber: day, isInCurrentMonth: true))
            }
        }
        
        // Add next month's leading days
        let remainingDays = 42 - days.count // 6 weeks * 7 days
        for day in 1...remainingDays {
            if let date = calendar.date(byAdding: .day, value: day - monthRange.count - 1, to: firstOfMonth) {
                days.append(CalendarDay(date: date, dayNumber: day, isInCurrentMonth: false))
            }
        }
        
        calendarDays = days
    }
    
    private func loadWorkouts(for date: Date) {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return }
        
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                       monthInterval.start as CVarArg,
                                       monthInterval.end as CVarArg)
        
        do {
            let workouts = try context.fetch(request)
            
            // Group workouts by day
            var grouped: [Date: [Workout]] = [:]
            for workout in workouts {
                guard let workoutDate = workout.date else { continue }
                let startOfDay = calendar.startOfDay(for: workoutDate)
                grouped[startOfDay, default: []].append(workout)
            }
            
            workoutsInMonth = grouped
        } catch {
            print("Error loading workouts: \(error)")
        }
    }
}

// MARK: - Models

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let dayNumber: Int
    let isInCurrentMonth: Bool
}
