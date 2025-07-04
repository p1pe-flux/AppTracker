//
//  Theme.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 29/6/25.
//

import SwiftUI

// MARK: - App Theme

struct Theme {
    // MARK: - Colors
    
    struct Colors {
        // Primary colors
        static let primary = Color.accentColor
        static let secondary = Color.secondary
        
        // Exercise category colors
        static let chest = Color(red: 0.96, green: 0.26, blue: 0.21)
        static let back = Color(red: 0.13, green: 0.59, blue: 0.95)
        static let shoulders = Color(red: 1.0, green: 0.60, blue: 0.0)
        static let biceps = Color(red: 0.55, green: 0.76, blue: 0.29)
        static let triceps = Color(red: 0.61, green: 0.15, blue: 0.69)
        static let legs = Color(red: 0.0, green: 0.74, blue: 0.83)
        static let core = Color(red: 1.0, green: 0.76, blue: 0.03)
        static let cardio = Color(red: 0.96, green: 0.26, blue: 0.21)
        static let other = Color.gray
        
        // Status colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Gradient colors
        static let gradientStart = Color(red: 0.29, green: 0.46, blue: 0.95)
        static let gradientEnd = Color(red: 0.13, green: 0.59, blue: 0.95)
        
        static let successGradientStart = Color(red: 0.30, green: 0.85, blue: 0.39)
        static let successGradientEnd = Color(red: 0.20, green: 0.73, blue: 0.29)
    }
    
    // MARK: - Gradients
    
    struct Gradients {
        static let primary = LinearGradient(
            colors: [Colors.gradientStart, Colors.gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let success = LinearGradient(
            colors: [Colors.successGradientStart, Colors.successGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cardBackground = LinearGradient(
            colors: [
                Color(UIColor.secondarySystemBackground),
                Color(UIColor.secondarySystemBackground).opacity(0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 20
    }
    
    // MARK: - Shadows
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    struct Shadows {
        static let small = Shadow(
            color: Color.black.opacity(0.1),
            radius: 2,
            x: 0,
            y: 1
        )
        
        static let medium = Shadow(
            color: Color.black.opacity(0.15),
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let large = Shadow(
            color: Color.black.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
    }
    
    // MARK: - Animation
    
    struct Animation {
        static let fast: SwiftUI.Animation = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let medium: SwiftUI.Animation = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow: SwiftUI.Animation = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring: SwiftUI.Animation = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
    }
}

// MARK: - Exercise Category Color Extension

extension ExerciseCategory {
    var color: Color {
        switch self {
        case .chest: return Theme.Colors.chest
        case .back: return Theme.Colors.back
        case .shoulders: return Theme.Colors.shoulders
        case .biceps: return Theme.Colors.biceps
        case .triceps: return Theme.Colors.triceps
        case .legs: return Theme.Colors.legs
        case .core: return Theme.Colors.core
        case .cardio: return Theme.Colors.cardio
        case .other: return Theme.Colors.other
        }
    }
}

// MARK: - Custom Environment Values

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme()
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - View Extensions for Theme

extension View {
    func primaryGradient() -> some View {
        self.foregroundGradient(Theme.Gradients.primary)
    }
    
    func successGradient() -> some View {
        self.foregroundGradient(Theme.Gradients.success)
    }
    
    func cardShadow() -> some View {
        self.shadow(
            color: Theme.Shadows.medium.color,
            radius: Theme.Shadows.medium.radius,
            x: Theme.Shadows.medium.x,
            y: Theme.Shadows.medium.y
        )
    }
}
