import Foundation

/// Matches server weight_unit values exactly.
enum WeightUnit: String, Codable, Equatable {
    case kg
    case lbs

    var label: String { rawValue }

    var increment: Double {
        switch self {
        case .kg: return 2.5
        case .lbs: return 5.0
        }
    }

    func roundToNearest(_ value: Double) -> Double {
        let inc = increment
        return (value / inc).rounded() * inc
    }
}
