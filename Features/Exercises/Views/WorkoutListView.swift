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
    @State private var showingCalendar = false
    @State private var showingDuplicateSheet = false
    @State private var workoutToDuplicate: Workout?
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        _viewModel = StateObject(wrappedValue: WorkoutViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Today's workouts section
                if !viewModel.todayWorkouts.isEmpty {
                                    todaySection
                                }
                
                // Quick actions section
                if !viewModel.workouts.isEmpty {
                     QuickActionsSection(viewModel: viewModel)
                         .padding(.vertical)
                     
                     Divider()
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingCalendar = true }) {
                        Image(systemName: "calendar")
                    }
                }
                
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
            .sheet(isPresented: $showingCalendar) {
                WorkoutCalendarView(context: context)
            }
            .sheet(isPresented: $showingDuplicateSheet) {
                if let workout = workoutToDuplicate {
                    DuplicateWorkoutView(workout: workout)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.showError = false }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
        .overlay(alignment: .bottomTrailing) {
            FloatingActionButton()
                .padding()
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
                        .contextMenu {
                            Button(action: {
                                duplicateWorkoutToTomorrow(workout)
                            }) {
                                Label("Duplicate to Tomorrow", systemImage: "calendar.badge.plus")
                            }
                            
                            Button(action: {
                                // Start workout
                            }) {
                                Label("Start Now", systemImage: "play.circle")
                            }
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
        
        private func duplicateWorkoutToTomorrow(_ workout: Workout) {
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                let duplicationService = WorkoutDuplicationService(context: context)
                
                Task {
                    do {
                        _ = try duplicationService.duplicateWorkout(workout, toDate: tomorrow)
                        HapticManager.shared.notification(.success)
                        viewModel.loadWorkouts()
                    } catch {
                        print("Error duplicating workout: \(error)")
                    }
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
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    duplicateWorkoutToToday(workout)
                                } label: {
                                    Label("Today", systemImage: "calendar.badge.plus")
                                }
                                .tint(Theme.Colors.primary)
                                
                                Button {
                                    duplicateWorkoutToTomorrow(workout)
                                } label: {
                                    Label("Tomorrow", systemImage: "calendar.badge.clock")
                                }
                                .tint(Theme.Colors.shoulders)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteWorkout(workout)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    showingDuplicateSheet = true
                                    workoutToDuplicate = workout
                                } label: {
                                    Label("Custom", systemImage: "calendar")
                                }
                                .tint(Theme.Colors.info)
                            }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private func duplicateWorkoutToToday(_ workout: Workout) {
        duplicateWorkout(workout, to: Date(), name: "\(workout.wrappedName) - Today")
    }
    
    private func duplicateWorkout(_ workout: Workout, to date: Date, name: String? = nil) {
        let duplicationService = WorkoutDuplicationService(context: context)
        
        Task {
            do {
                _ = try duplicationService.duplicateWorkout(
                    workout,
                    toDate: date,
                    withName: name
                )
                HapticManager.shared.notification(.success)
                viewModel.loadWorkouts()
            } catch {
                viewModel.errorMessage = "Failed to duplicate workout"
                viewModel.showError = true
            }
        }
    }
    
    private func deleteWorkout(_ workout: Workout) {
        Task {
            await viewModel.deleteWorkout(workout)
        }
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
    @Environment(\.managedObjectContext) private var context
    @State private var showingDuplicateSheet = false
    @State private var showingActions = false
    @State private var showingQuickDuplicate = false
    
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
            
            // Quick duplicate button
            Button(action: { showingQuickDuplicate = true }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.primary)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Theme.Colors.primary.opacity(0.1))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            Menu {
                Button(action: { showingDuplicateSheet = true }) {
                    Label("Duplicate with Custom Date", systemImage: "calendar")
                }
                
                Button(action: { duplicateToTomorrow() }) {
                    Label("Duplicate to Tomorrow", systemImage: "calendar.badge.plus")
                }
                
                Button(action: { createTemplate() }) {
                    Label("Save as Template", systemImage: "square.and.arrow.down")
                }
                
                Divider()
                
                Button(role: .destructive, action: { /* Delete */ }) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingDuplicateSheet) {
            DuplicateWorkoutView(workout: workout)
        }
        .confirmationDialog("Quick Duplicate", isPresented: $showingQuickDuplicate) {
            Button("Duplicate to Today") {
                duplicateToToday()
            }
            
            Button("Duplicate to Tomorrow") {
                duplicateToTomorrow()
            }
            
            Button("Duplicate to Next Week") {
                duplicateToNextWeek()
            }
            
            Button("Custom Date...") {
                showingDuplicateSheet = true
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("When would you like to schedule this workout?")
        }
    }
    
    // MARK: - Quick Actions
    
    private func duplicateToToday() {
        duplicateWorkout(to: Date())
    }
    
    private func duplicateToTomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        duplicateWorkout(to: tomorrow)
    }
    
    private func duplicateToNextWeek() {
        let nextWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())!
        duplicateWorkout(to: nextWeek)
    }
    
    private func duplicateWorkout(to date: Date) {
        let duplicationService = WorkoutDuplicationService(context: context)
        
        Task {
            do {
                _ = try duplicationService.duplicateWorkout(workout, toDate: date)
                HapticManager.shared.notification(.success)
            } catch {
                print("Error duplicating workout: \(error)")
            }
        }
    }
    
    private func createTemplate() {
        let duplicationService = WorkoutDuplicationService(context: context)
        
        Task {
            do {
                _ = try duplicationService.createTemplate(
                    from: workout,
                    templateName: "\(workout.wrappedName) Template"
                )
                HapticManager.shared.notification(.success)
            } catch {
                print("Error creating template: \(error)")
            }
        }
    }
}

// Agregar este widget a WorkoutListView.swift

struct QuickActionsSection: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @Environment(\.managedObjectContext) private var context
    @State private var showingTemplates = false
    
    private var recentWorkouts: [Workout] {
        Array(viewModel.workouts.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.medium) {
                    // Create new workout
                    QuickActionCard(
                        title: "New Workout",
                        icon: "plus.circle.fill",
                        color: Theme.Colors.primary
                    ) {
                        // Navigate to create workout
                    }
                    
                    // Use template
                    QuickActionCard(
                        title: "From Template",
                        icon: "doc.text.fill",
                        color: Theme.Colors.shoulders
                    ) {
                        showingTemplates = true
                    }
                    
                    // Recent workouts to duplicate
                    ForEach(recentWorkouts) { workout in
                        QuickDuplicateCard(workout: workout)
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingTemplates) {
            TemplateListView()
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.small) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(color)
                    )
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 100, height: 100)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(color.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickDuplicateCard: View {
    let workout: Workout
    @Environment(\.managedObjectContext) private var context
    @State private var showingOptions = false
    
    var body: some View {
        Button(action: { showingOptions = true }) {
            VStack(spacing: Theme.Spacing.small) {
                Image(systemName: "doc.on.doc.fill")
                    .font(.title2)
                    .foregroundColor(Theme.Colors.primary)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Theme.Colors.primary.opacity(0.2))
                    )
                
                Text(workout.wrappedName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text(workout.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 100, height: 120)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog("Duplicate '\(workout.wrappedName)'", isPresented: $showingOptions) {
            Button("To Today") {
                duplicateWorkout(to: Date())
            }
            
            Button("To Tomorrow") {
                duplicateWorkout(to: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
            }
            
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func duplicateWorkout(to date: Date) {
        let duplicationService = WorkoutDuplicationService(context: context)
        
        Task {
            do {
                _ = try duplicationService.duplicateWorkout(workout, toDate: date)
                HapticManager.shared.notification(.success)
            } catch {
                print("Error duplicating workout: \(error)")
            }
        }
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


// Estructura del Floating Action Button
struct FloatingActionButton: View {
    @State private var isExpanded = false
    @State private var showingCreateWorkout = false
    @State private var showingTemplates = false
    @State private var showingLastWorkout = false
    @Environment(\.managedObjectContext) private var context
    
    var lastWorkout: Workout? {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.date, ascending: false)]
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if isExpanded {
                // Mini action buttons
                VStack(spacing: 12) {
                    // Duplicate last workout
                    if lastWorkout != nil {
                        MiniActionButton(
                            icon: "doc.on.doc",
                            label: "Repeat Last",
                            color: Theme.Colors.shoulders
                        ) {
                            showingLastWorkout = true
                        }
                    }
                    
                    // From template
                    MiniActionButton(
                        icon: "doc.text",
                        label: "Template",
                        color: Theme.Colors.info
                    ) {
                        showingTemplates = true
                    }
                    
                    // New workout
                    MiniActionButton(
                        icon: "plus",
                        label: "New",
                        color: Theme.Colors.success
                    ) {
                        showingCreateWorkout = true
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Main FAB button
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                    HapticManager.shared.impact(.light)
                }
            }) {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(Theme.Gradients.primary)
                            .shadow(
                                color: Theme.Colors.primary.opacity(0.3),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                    )
            }
        }
        .confirmationDialog("Repeat Last Workout", isPresented: $showingLastWorkout) {
            if let workout = lastWorkout {
                Button("Repeat Today") {
                    duplicateWorkout(workout, to: Date())
                }
                
                Button("Repeat Tomorrow") {
                    duplicateWorkout(workout, to: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
                }
                
                Button("Custom Date") {
                    // Show date picker
                }
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            if let workout = lastWorkout {
                Text("Repeat '\(workout.wrappedName)'?")
            }
        }
        .sheet(isPresented: $showingCreateWorkout) {
            // Create workout view
        }
        .sheet(isPresented: $showingTemplates) {
            // Templates view
        }
    }
    
    private func duplicateWorkout(_ workout: Workout, to date: Date) {
        let duplicationService = WorkoutDuplicationService(context: context)
        
        Task {
            do {
                _ = try duplicationService.duplicateWorkout(workout, toDate: date)
                HapticManager.shared.notification(.success)
                isExpanded = false
            } catch {
                print("Error duplicating workout: \(error)")
            }
        }
    }
}

struct MiniActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(UIColor.systemBackground))
                            .shadow(
                                color: Color.black.opacity(0.1),
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                    )
                
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color)
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}





struct TemplateListView: View {
    var body: some View {
        NavigationView {
            Text("Template list placeholder")
                .navigationTitle("Templates")
        }
    }
}
