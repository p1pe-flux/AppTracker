//
//  UserPreferences.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 4/7/25.
//


//
//  UserPreferences.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 3/7/25.
//

import SwiftUI
import Combine

// MARK: - User Preferences

class UserPreferences: ObservableObject {
    static let shared = UserPreferences()
    
    // MARK: - Weight Unit
    
    enum WeightUnit: String, CaseIterable {
        case kilograms = "kg"
        case pounds = "lbs"
        
        var name: String {
            switch self {
            case .kilograms: return "Kilograms"
            case .pounds: return "Pounds"
            }
        }
        
        func convert(_ value: Double, to unit: WeightUnit) -> Double {
            if self == unit { return value }
            
            switch (self, unit) {
            case (.kilograms, .pounds):
                return value * 2.20462
            case (.pounds, .kilograms):
                return value / 2.20462
            default:
                return value
            }
        }
    }
    
    // MARK: - Rest Timer Preferences
    
    struct RestTimerSettings {
        var defaultRestTime: Int = 90
        var autoStartTimer: Bool = true
        var playSound: Bool = true
        var vibrate: Bool = true
    }
    
    // MARK: - Workout Preferences
    
    struct WorkoutSettings {
        var warmupReminder: Bool = true
        var autoAddSets: Bool = false
        var showPreviousWorkout: Bool = true
        var quickStartEnabled: Bool = true
    }
    
    // MARK: - Published Properties
    
    @AppStorage("weightUnit") var weightUnit: WeightUnit = .kilograms {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("defaultRestTime") var defaultRestTime: Int = 90 {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("autoStartRestTimer") var autoStartRestTimer: Bool = true {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("playTimerSound") var playTimerSound: Bool = true {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("enableHaptics") var enableHaptics: Bool = true {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("showWarmupReminder") var showWarmupReminder: Bool = true {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("autoAddSets") var autoAddSets: Bool = false {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("showPreviousWorkout") var showPreviousWorkout: Bool = true {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("quickStartEnabled") var quickStartEnabled: Bool = true {
        didSet { objectWillChange.send() }
    }
    
    // Theme preferences
    @AppStorage("appTheme") var appTheme: AppTheme = .system {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("useLargerText") var useLargerText: Bool = false {
        didSet { objectWillChange.send() }
    }
    
    // MARK: - Methods
    
    func convertWeight(_ weight: Double, from: WeightUnit? = nil) -> Double {
        let sourceUnit = from ?? weightUnit
        return sourceUnit.convert(weight, to: weightUnit)
    }
    
    func formatWeight(_ weight: Double) -> String {
        let converted = convertWeight(weight)
        if converted.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f %@", converted, weightUnit.rawValue)
        } else {
            return String(format: "%.1f %@", converted, weightUnit.rawValue)
        }
    }
    
    func resetToDefaults() {
        weightUnit = .kilograms
        defaultRestTime = 90
        autoStartRestTimer = true
        playTimerSound = true
        enableHaptics = true
        showWarmupReminder = true
        autoAddSets = false
        showPreviousWorkout = true
        quickStartEnabled = true
        appTheme = .system
        useLargerText = false
    }
}

// MARK: - App Theme

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Environment Extensions

private struct UserPreferencesKey: EnvironmentKey {
    static let defaultValue = UserPreferences.shared
}

extension EnvironmentValues {
    var userPreferences: UserPreferences {
        get { self[UserPreferencesKey.self] }
        set { self[UserPreferencesKey.self] = newValue }
    }
}

// MARK: - View Extensions

extension View {
    func applyUserPreferences() -> some View {
        self
            .environment(\.userPreferences, UserPreferences.shared)
            .preferredColorScheme(UserPreferences.shared.appTheme.colorScheme)
    }
    
    func withHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onTapGesture {
            if UserPreferences.shared.enableHaptics {
                HapticManager.shared.impact(style)
            }
        }
    }
}

// MARK: - Quick Settings View

struct QuickSettingsView: View {
    @ObservedObject private var preferences = UserPreferences.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Units")) {
                    Picker("Weight Unit", selection: $preferences.weightUnit) {
                        ForEach(UserPreferences.WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.name).tag(unit)
                        }
                    }
                }
                
                Section(header: Text("Rest Timer")) {
                    HStack {
                        Text("Default Rest Time")
                        Spacer()
                        QuickTimerSelector(selectedSeconds: $preferences.defaultRestTime)
                            .labelsHidden()
                    }
                    
                    Toggle("Auto-start Timer", isOn: $preferences.autoStartRestTimer)
                    Toggle("Play Sound", isOn: $preferences.playTimerSound)
                    Toggle("Haptic Feedback", isOn: $preferences.enableHaptics)
                }
                
                Section(header: Text("Workout")) {
                    Toggle("Warmup Reminder", isOn: $preferences.showWarmupReminder)
                    Toggle("Show Previous Workout", isOn: $preferences.showPreviousWorkout)
                    Toggle("Quick Start", isOn: $preferences.quickStartEnabled)
                }
                
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $preferences.appTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    
                    Toggle("Use Larger Text", isOn: $preferences.useLargerText)
                }
                
                Section {
                    Button("Reset to Defaults") {
                        preferences.resetToDefaults()
                        HapticManager.shared.notification(.warning)
                    }
                    .foregroundColor(Theme.Colors.error)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
