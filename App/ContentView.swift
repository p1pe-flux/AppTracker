//
//  ContentView.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedTab") private var selectedTab = 0
    @State private var showingOnboarding = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Workouts Tab
            WorkoutListView(context: viewContext)
                .tabItem {
                    Label("Workouts", systemImage: "dumbbell")
                }
                .tag(0)
                .badge(todayWorkoutCount)
            
            // Exercises Tab
            ExerciseListView(context: viewContext)
                .tabItem {
                    Label("Exercises", systemImage: "figure.arms.open")
                }
                .tag(1)
            
            // Statistics Tab
            StatisticsView(context: viewContext)
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar")
                }
                .tag(2)
            
            // Profile Tab
            ProfilePlaceholderView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(3)
        }
        .accentColor(Theme.Colors.primary)
        .onAppear {
            setupInitialData()
            checkOnboarding()
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView(isPresented: $showingOnboarding)
        }
    }
    
    private var todayWorkoutCount: Int {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@ AND duration == 0",
            startOfDay as CVarArg,
            endOfDay as CVarArg
        )
        
        do {
            return try viewContext.count(for: request)
        } catch {
            return 0
        }
    }
    
    private func setupInitialData() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            ExerciseRepository.createPreviewExercises(in: viewContext)
            WorkoutRepository.createPreviewWorkouts(in: viewContext)
        }
        #endif
    }
    
    private func checkOnboarding() {
        if !hasCompletedOnboarding {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingOnboarding = true
            }
        }
    }
}

// MARK: - Placeholder Views

struct StatisticsPlaceholderView: View {
    var body: some View {
        NavigationView {
            EmptyStateView(
                icon: "chart.line.uptrend.xyaxis",
                title: "Statistics Coming Soon",
                message: "Track your progress with detailed analytics and insights",
                actionTitle: nil,
                action: nil
            )
            .navigationTitle("Statistics")
        }
    }
}

struct ProfilePlaceholderView: View {
    var body: some View {
        NavigationView {
            EmptyStateView(
                icon: "person.circle",
                title: "Profile Coming Soon",
                message: "Manage your settings and preferences",
                actionTitle: nil,
                action: nil
            )
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    let pages: [(title: String, subtitle: String, icon: String, color: Color)] = [
        (
            title: "Welcome to Workout Tracker",
            subtitle: "Your personal fitness companion for tracking workouts and progress",
            icon: "figure.strengthtraining.traditional",
            color: Theme.Colors.primary
        ),
        (
            title: "Track Your Workouts",
            subtitle: "Log exercises, sets, and reps with our intuitive interface",
            icon: "dumbbell",
            color: Theme.Colors.chest
        ),
        (
            title: "Monitor Progress",
            subtitle: "View detailed statistics and watch your strength grow over time",
            icon: "chart.line.uptrend.xyaxis",
            color: Theme.Colors.success
        ),
        (
            title: "Ready to Start?",
            subtitle: "Let's begin your fitness journey today!",
            icon: "checkmark.circle.fill",
            color: Theme.Colors.primary
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    completeOnboarding()
                }
                .foregroundColor(.secondary)
                .padding()
            }
            
            // Content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPage(
                        title: pages[index].title,
                        subtitle: pages[index].subtitle,
                        icon: pages[index].icon,
                        color: pages[index].color
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Theme.Colors.primary : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding()
            
            // Action button
            Button(action: {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    completeOnboarding()
                }
            }) {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.bottom, Theme.Spacing.xLarge)
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        HapticManager.shared.notification(.success)
        withAnimation {
            isPresented = false
        }
    }
}

struct OnboardingPage: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xLarge) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 100))
                .foregroundColor(color)
                .padding()
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 200, height: 200)
                )
            
            VStack(spacing: Theme.Spacing.medium) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xLarge)
            }
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
