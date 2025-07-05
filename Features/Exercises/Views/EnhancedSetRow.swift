//
//  EnhancedSetRow.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 5/7/25.
//


//
//  EnhancedSetRow.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 04/07/25.
//

import SwiftUI

struct EnhancedSetRow: View {
    let set: WorkoutSet
    @ObservedObject var viewModel: ActiveWorkoutViewModel
    
    @State private var weight: String = ""
    @State private var reps: String = ""
    @State private var restTime: String = ""
    @State private var showingRestTimePicker = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case weight, reps, restTime
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            HStack(spacing: 12) {
                // Set number
                Text("\(set.setNumber)")
                    .frame(width: 30, alignment: .center)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(set.completed ? .secondary : .primary)
                
                // Weight input
                VStack(spacing: 4) {
                    Text("Weight")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    TextField("0", text: $weight)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .weight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(UIColor.tertiarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(focusedField == .weight ? Color.accentColor : Color.clear, lineWidth: 1)
                        )
                        .onChange(of: weight) { _ in updateSet() }
                }
                
                // Reps input
                VStack(spacing: 4) {
                    Text("Reps")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    TextField("0", text: $reps)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .reps)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(UIColor.tertiarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(focusedField == .reps ? Color.accentColor : Color.clear, lineWidth: 1)
                        )
                        .onChange(of: reps) { _ in updateSet() }
                }
                
                // Rest time
                VStack(spacing: 4) {
                    Text("Rest")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Button(action: { showingRestTimePicker = true }) {
                        Text(formatRestTime(Int(set.restTime)))
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(UIColor.tertiarySystemBackground))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(width: 60)
                
                // Complete button
                Button(action: toggleCompletion) {
                    Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(set.completed ? .green : .secondary)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Previous set info (if available)
            if let previousSet = getPreviousSet() {
                HStack {
                    Image(systemName: "arrow.backward")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Previous: \(UserPreferences.shared.formatWeight(previousSet.weight)) × \(previousSet.reps)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.leading, 40)
            }
        }
        .onAppear {
            weight = set.weight > 0 ? set.formattedWeight : ""
            reps = set.reps > 0 ? "\(set.reps)" : ""
            restTime = "\(set.restTime)"
        }
        .sheet(isPresented: $showingRestTimePicker) {
            RestTimePickerView(seconds: Binding(
                get: { Int(set.restTime) },
                set: { newValue in
                    Task {
                        await viewModel.updateSet(set, weight: nil, reps: nil, restTime: Int16(newValue), completed: nil)
                    }
                }
            ))
        }
    }
    
    private func updateSet() {
        Task {
            let weightValue = Double(weight) ?? 0
            let repsValue = Int16(reps) ?? 0
            
            await viewModel.updateSet(set, weight: weightValue, reps: repsValue, restTime: nil, completed: nil)
        }
    }
    
    private func toggleCompletion() {
        Task {
            await viewModel.updateSet(set, weight: nil, reps: nil, restTime: nil, completed: !set.completed)
            
            // Start rest timer if completing a set
            if !set.completed && set.restTime > 0 && UserPreferences.shared.autoStartRestTimer {
                viewModel.startRestTimer(seconds: Int(set.restTime))
            }
            
            HapticManager.shared.impact(.medium)
        }
    }
    
    private func getPreviousSet() -> WorkoutSet? {
        // Logic to get previous set from workout history
        // This would need to be implemented based on your data structure
        return nil
    }
    
    private func formatRestTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes)m"
            } else {
                return "\(minutes):\(String(format: "%02d", remainingSeconds))"
            }
        }
    }
}

// MARK: - Rest Time Picker View

struct RestTimePickerView: View {
    @Binding var seconds: Int
    @Environment(\.dismiss) private var dismiss
    
    private let quickOptions = [30, 45, 60, 90, 120, 180, 240, 300]
    @State private var minutes: Int = 0
    @State private var remainingSeconds: Int = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: Theme.Spacing.large) {
                // Quick selection
                VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                    Text("Quick Select")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: Theme.Spacing.small) {
                        ForEach(quickOptions, id: \.self) { option in
                            Button(action: {
                                seconds = option
                                dismiss()
                            }) {
                                Text(formatTime(option))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                            .fill(seconds == option ? Theme.Colors.primary : Color(UIColor.tertiarySystemBackground))
                                    )
                                    .foregroundColor(seconds == option ? .white : .primary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Divider()
                
                // Custom time picker
                VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                    Text("Custom Time")
                        .font(.headline)
                    
                    HStack {
                        VStack {
                            Text("Minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("Minutes", selection: $minutes) {
                                ForEach(0..<10) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100)
                        }
                        
                        Text(":")
                            .font(.title)
                            .fontWeight(.medium)
                        
                        VStack {
                            Text("Seconds")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("Seconds", selection: $remainingSeconds) {
                                ForEach(0..<60) { second in
                                    Text(String(format: "%02d", second)).tag(second)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Rest Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        seconds = (minutes * 60) + remainingSeconds
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .onAppear {
                minutes = seconds / 60
                remainingSeconds = seconds % 60
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let mins = seconds / 60
            let secs = seconds % 60
            if secs == 0 {
                return "\(mins)m"
            } else {
                return "\(mins):\(String(format: "%02d", secs))"
            }
        }
    }
}