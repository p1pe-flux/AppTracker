//
//  ValidationResult.swift
//  Workout Tracker
//
//  Created by Felipe Guasch on 3/7/25.
//

import Foundation

// MARK: - Validation Result

enum ValidationResult {
    case valid
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .valid: return true
        case .invalid: return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid: return nil
        case .invalid(let message): return message
        }
    }
}

// MARK: - Validators

struct Validators {
    // MARK: - Text Validators
    
    static func validateExerciseName(_ name: String) -> ValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .invalid("Exercise name cannot be empty")
        }
        
        if trimmed.count < 2 {
            return .invalid("Exercise name must be at least 2 characters")
        }
        
        if trimmed.count > 50 {
            return .invalid("Exercise name must be less than 50 characters")
        }
        
        // Check for special characters
        let allowedCharacters = CharacterSet.alphanumerics.union(.whitespaces).union(CharacterSet(charactersIn: "-"))
        if trimmed.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            return .invalid("Exercise name contains invalid characters")
        }
        
        return .valid
    }
    
    static func validateWorkoutName(_ name: String) -> ValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .invalid("Workout name cannot be empty")
        }
        
        if trimmed.count > 50 {
            return .invalid("Workout name must be less than 50 characters")
        }
        
        return .valid
    }
    
    static func validateNotes(_ notes: String) -> ValidationResult {
        if notes.count > 500 {
            return .invalid("Notes must be less than 500 characters")
        }
        
        return .valid
    }
    
    // MARK: - Numeric Validators
    
    static func validateWeight(_ weight: Double) -> ValidationResult {
        if weight < 0 {
            return .invalid("Weight cannot be negative")
        }
        
        if weight > 1000 {
            return .invalid("Weight seems too high. Please check the value")
        }
        
        return .valid
    }
    
    static func validateReps(_ reps: Int) -> ValidationResult {
        if reps < 0 {
            return .invalid("Reps cannot be negative")
        }
        
        if reps > 1000 {
            return .invalid("Reps seem too high. Please check the value")
        }
        
        return .valid
    }
    
    static func validateRestTime(_ seconds: Int) -> ValidationResult {
        if seconds < 0 {
            return .invalid("Rest time cannot be negative")
        }
        
        if seconds > 600 { // 10 minutes
            return .invalid("Rest time seems too long. Maximum is 10 minutes")
        }
        
        return .valid
    }
    
    // MARK: - Date Validators
    
    static func validateWorkoutDate(_ date: Date) -> ValidationResult {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if date is too far in the future (more than 1 week)
        if let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now),
           date > weekFromNow {
            return .invalid("Workout date cannot be more than 1 week in the future")
        }
        
        // Check if date is too far in the past (more than 1 year)
        if let yearAgo = calendar.date(byAdding: .year, value: -1, to: now),
           date < yearAgo {
            return .invalid("Workout date cannot be more than 1 year in the past")
        }
        
        return .valid
    }
}

// MARK: - Form Validation

protocol FormValidatable {
    var isValid: Bool { get }
    var validationErrors: [String] { get }
}

// MARK: - Input Sanitizers

struct InputSanitizer {
    static func sanitizeNumericInput(_ input: String, allowDecimal: Bool = false) -> String {
        let allowedCharacters = allowDecimal ? "0123456789." : "0123456789"
        let filtered = input.filter { allowedCharacters.contains($0) }
        
        if allowDecimal {
            // Ensure only one decimal point
            let components = filtered.split(separator: ".")
            if components.count > 2 {
                return String(components[0]) + "." + components[1...].joined()
            }
        }
        
        return filtered
    }
    
    static func sanitizeTextInput(_ input: String, maxLength: Int? = nil) -> String {
        var sanitized = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove multiple consecutive spaces
        while sanitized.contains("  ") {
            sanitized = sanitized.replacingOccurrences(of: "  ", with: " ")
        }
        
        // Apply max length if specified
        if let maxLength = maxLength, sanitized.count > maxLength {
            sanitized = String(sanitized.prefix(maxLength))
        }
        
        return sanitized
    }
}

// MARK: - Validation Extensions

extension String {
    var isValidExerciseName: Bool {
        Validators.validateExerciseName(self).isValid
    }
    
    var isValidWorkoutName: Bool {
        Validators.validateWorkoutName(self).isValid
    }
    
    var isNumeric: Bool {
        !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    
    var isDecimal: Bool {
        guard !isEmpty else { return false }
        let components = split(separator: ".")
        if components.count > 2 { return false }
        return components.allSatisfy { String($0).isNumeric }
    }
}

extension Double {
    var isValidWeight: Bool {
        Validators.validateWeight(self).isValid
    }
}

extension Int {
    var isValidReps: Bool {
        Validators.validateReps(self).isValid
    }
    
    var isValidRestTime: Bool {
        Validators.validateRestTime(self).isValid
    }
}
