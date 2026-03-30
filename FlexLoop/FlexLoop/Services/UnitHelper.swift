import Foundation

/// WeightUnit raw values match the server's weight_unit field exactly ("kg" or "lbs").
/// This eliminates any mapping between iOS enum values and server strings.
enum WeightUnit: String, Codable {
    case kg
    case lbs

    var symbol: String { rawValue }

    var heightSymbol: String {
        switch self {
        case .kg: return "cm"
        case .lbs: return "in"
        }
    }

    /// Weight increment for digital crown / steppers
    var increment: Double {
        switch self {
        case .kg: return 2.5
        case .lbs: return 5.0
        }
    }

    var barbellIncrement: Double {
        switch self {
        case .kg: return 5.0
        case .lbs: return 10.0
        }
    }

    var barbellMinimum: Double {
        switch self {
        case .kg: return 20.0
        case .lbs: return 45.0
        }
    }

    var dumbbellIncrement: Double {
        switch self {
        case .kg: return 2.5
        case .lbs: return 5.0
        }
    }

    /// Round a value to the nearest valid weight for the given equipment
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

    /// Format a weight value for display
    func format(_ value: Double) -> String {
        "\(String(format: "%.1f", value)) \(symbol)"
    }
}
