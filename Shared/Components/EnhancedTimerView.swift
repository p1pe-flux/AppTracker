//
//  EnhancedTimerView.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import SwiftUI
import AVFoundation

// MARK: - Rest Timer View

struct RestTimerView: View {
    @Binding var seconds: Int
    @Binding var isRunning: Bool
    let totalSeconds: Int
    let onSkip: () -> Void
    
    @State private var animateRing = false
    @State private var animatePulse = false
    
    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - seconds) / Double(totalSeconds)
    }
    
    private var timeString: String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            ZStack {
                // Background pulse effect
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.1))
                    .frame(width: 250, height: 250)
                    .scaleEffect(animatePulse ? 1.1 : 1.0)
                    .opacity(animatePulse ? 0 : 1)
                    .animation(
                        Animation.easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: animatePulse
                    )
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Theme.Gradients.primary,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: progress)
                }
                .frame(width: 200, height: 200)
                
                // Timer display
                VStack(spacing: 8) {
                    Text("Rest Timer")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(timeString)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .primaryGradient()
                    
                    Text("\(totalSeconds)s total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Control buttons
            HStack(spacing: Theme.Spacing.medium) {
                Button(action: {
                    HapticManager.shared.impact(.medium)
                    addTime(15)
                }) {
                    Label("+15s", systemImage: "plus.circle")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .buttonStyle(SecondaryButtonStyle())
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    HapticManager.shared.impact(.light)
                    onSkip()
                }) {
                    Label("Skip", systemImage: "forward.fill")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xLarge)
                .fill(Color(UIColor.systemBackground))
                .cardShadow()
        )
        .onAppear {
            animatePulse = true
        }
        .onChange(of: seconds) { _, newValue in
            if newValue == 0 {
                HapticManager.shared.notification(.success)
                playSound()
            } else if newValue <= 3 && newValue > 0 {
                HapticManager.shared.impact(.light)
            }
        }
    }
    
    private func addTime(_ seconds: Int) {
        self.seconds += seconds
    }
    
    private func playSound() {
        AudioServicesPlaySystemSound(1005) // System sound for timer complete
    }
}

// MARK: - Workout Timer View

struct WorkoutTimerView: View {
    let elapsedTime: TimeInterval
    let isRunning: Bool
    let onPause: () -> Void
    let onResume: () -> Void
    
    @State private var pulseAnimation = false
    
    private var timeString: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            // Timer display
            HStack(spacing: Theme.Spacing.small) {
                Image(systemName: "timer")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Text(timeString)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .primaryGradient()
                
                if isRunning {
                    Circle()
                        .fill(Theme.Colors.success)
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )
                }
            }
            
            // Control button
            Button(action: {
                HapticManager.shared.impact(.light)
                if isRunning {
                    onPause()
                } else {
                    onResume()
                }
            }) {
                HStack {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    Text(isRunning ? "Pause" : "Resume")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(minWidth: 100)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .onAppear {
            if isRunning {
                pulseAnimation = true
            }
        }
        .onChange(of: isRunning) { _, newValue in
            pulseAnimation = newValue
        }
    }
}

// MARK: - Quick Timer Selector

struct QuickTimerSelector: View {
    @Binding var selectedSeconds: Int
    let presets: [Int] = [30, 45, 60, 90, 120, 180]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("Rest Time")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.small) {
                    ForEach(presets, id: \.self) { seconds in
                        TimerPresetButton(
                            seconds: seconds,
                            isSelected: selectedSeconds == seconds
                        ) {
                            HapticManager.shared.selection()
                            selectedSeconds = seconds
                        }
                    }
                    
                    // Custom time button
                    Button(action: {
                        // Show custom time picker
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.caption)
                            Text("Custom")
                                .font(.caption2)
                        }
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                .fill(Color(UIColor.tertiarySystemBackground))
                        )
                    }
                }
            }
        }
    }
}

struct TimerPresetButton: View {
    let seconds: Int
    let isSelected: Bool
    let action: () -> Void
    
    private var displayText: String {
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes)m"
            } else {
                return "\(minutes):\(remainingSeconds)"
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(displayText)
                    .font(.headline)
                    .fontWeight(isSelected ? .bold : .medium)
                
                if isSelected {
                    Circle()
                        .fill(Theme.Colors.primary)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 60, height: 60)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .fill(isSelected ? Theme.Colors.primary.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
