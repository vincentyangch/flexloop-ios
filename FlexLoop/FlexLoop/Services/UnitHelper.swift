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
}
