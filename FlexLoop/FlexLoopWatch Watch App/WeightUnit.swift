import Foundation

enum WeightUnit: String, Equatable {
    case metric
    case imperial

    static var current: WeightUnit {
        let stored = UserDefaults.standard.string(forKey: "unitSystem") ?? "metric"
        return WeightUnit(rawValue: stored) ?? .metric
    }

    var label: String {
        switch self {
        case .metric: return "kg"
        case .imperial: return "lbs"
        }
    }

    func fromKg(_ kg: Double) -> Double {
        switch self {
        case .metric: return kg
        case .imperial: return kg * 2.20462
        }
    }

    func toKg(_ value: Double) -> Double {
        switch self {
        case .metric: return value
        case .imperial: return value / 2.20462
        }
    }

    func fromKgRounded(_ kg: Double) -> Double {
        let converted = fromKg(kg)
        let increment: Double = self == .metric ? 2.5 : 5.0
        return (converted / increment).rounded() * increment
    }
}
