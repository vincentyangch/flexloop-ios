import Foundation

enum WeightUnit: String {
    case metric  // kg
    case imperial  // lbs

    static var current: WeightUnit {
        let stored = UserDefaults.standard.string(forKey: "unitSystem") ?? "metric"
        return WeightUnit(rawValue: stored) ?? .metric
    }

    var symbol: String {
        switch self {
        case .metric: return "kg"
        case .imperial: return "lbs"
        }
    }

    var heightSymbol: String {
        switch self {
        case .metric: return "cm"
        case .imperial: return "in"
        }
    }

    /// Convert kg to display unit
    func fromKg(_ kg: Double) -> Double {
        switch self {
        case .metric: return kg
        case .imperial: return kg * 2.20462
        }
    }

    /// Convert display unit to kg for storage
    func toKg(_ value: Double) -> Double {
        switch self {
        case .metric: return value
        case .imperial: return value / 2.20462
        }
    }

    /// Convert cm to display unit for height
    func fromCm(_ cm: Double) -> Double {
        switch self {
        case .metric: return cm
        case .imperial: return cm / 2.54
        }
    }

    /// Convert display unit to cm for storage
    func toCm(_ value: Double) -> Double {
        switch self {
        case .metric: return value
        case .imperial: return value * 2.54
        }
    }

    /// Format weight for display
    func formatWeight(_ kg: Double) -> String {
        let value = fromKg(kg)
        return "\(String(format: "%.1f", value)) \(symbol)"
    }

    /// Weight increment for digital crown / steppers
    var increment: Double {
        switch self {
        case .metric: return 2.5
        case .imperial: return 5.0
        }
    }

    // MARK: - Equipment-aware increments and minimums

    /// Smallest plate increment (both sides of a barbell = 2 plates)
    /// Metric: 2.5kg plates → 5kg per step. Imperial: 5lb plates → 10lb per step.
    var barbellIncrement: Double {
        switch self {
        case .metric: return 5.0    // 2x 2.5kg plates
        case .imperial: return 10.0  // 2x 5lb plates
        }
    }

    /// Barbell bar weight
    var barbellMinimum: Double {
        switch self {
        case .metric: return 20.0   // standard Olympic bar
        case .imperial: return 45.0
        }
    }

    /// Dumbbell increment (single weight)
    var dumbbellIncrement: Double {
        switch self {
        case .metric: return 2.5
        case .imperial: return 5.0
        }
    }

    /// Round a display-unit value to the nearest valid weight for the given equipment
    func roundToNearest(_ value: Double, equipment: String) -> Double {
        let inc: Double
        let minimum: Double
        switch equipment.lowercased() {
        case "barbell":
            inc = barbellIncrement
            minimum = barbellMinimum
        case "dumbbell", "dumbbells":
            inc = dumbbellIncrement
            minimum = inc
        default:
            inc = increment
            minimum = inc
        }
        let rounded = (value / inc).rounded() * inc
        return max(rounded, minimum)
    }
}
