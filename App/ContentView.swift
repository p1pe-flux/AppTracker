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
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Workouts Tab
            NavigationView {
                VStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Text("Workouts Coming Soon")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .navigationTitle("Workouts")
            }
            .tabItem {
                Label("Workouts", systemImage: "dumbbell")
            }
            .tag(0)
            
            // Exercises Tab
            ExerciseListView(context: viewContext)
                .tabItem {
                    Label("Exercises", systemImage: "figure.arms.open")
                }
                .tag(1)
            
            // Statistics Tab
            NavigationView {
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Text("Statistics Coming Soon")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .navigationTitle("Statistics")
            }
            .tabItem {
                Label("Statistics", systemImage: "chart.bar")
            }
            .tag(2)
            
            // Profile Tab
            NavigationView {
                VStack {
                    Image(systemName: "person.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Text("Profile Coming Soon")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .navigationTitle("Profile")
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(3)
        }
        .onAppear {
            // Create preview data in debug mode
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                ExerciseRepository.createPreviewExercises(in: viewContext)
            }
            #endif
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
