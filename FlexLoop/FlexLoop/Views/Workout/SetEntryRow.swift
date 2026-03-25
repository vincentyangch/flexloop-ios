import SwiftUI

struct SetEntryRow: View {
    let setNumber: Int
    let previousWeight: Double?  // in kg
    let previousReps: Int?

    @Binding var weight: Double?  // stored in kg
    @Binding var reps: Int?
    @Binding var rpe: Double?
    @Binding var setType: SetType

    private let unit = WeightUnit.current

    /// Weight displayed/entered in user's unit
    private var displayWeight: Binding<Double?> {
        Binding(
            get: {
                guard let w = weight else { return nil }
                return unit.fromKg(w)
            },
            set: { newValue in
                guard let v = newValue else { weight = nil; return }
                weight = unit.toKg(v)
            }
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("\(setNumber)")
                .font(.caption.bold())
                .frame(width: 24)
                .foregroundStyle(setType == .warmUp ? .secondary : .primary)

            Menu {
                ForEach([SetType.warmUp, .working, .drop, .amrap, .backoff], id: \.self) { type in
                    Button(type.rawValue.replacingOccurrences(of: "_", with: " ").uppercased()) {
                        setType = type
                    }
                }
            } label: {
                Text(setType.rawValue.prefix(1).uppercased())
                    .font(.caption2.bold())
                    .padding(4)
                    .background(setType == .warmUp ? Color.gray.opacity(0.3) : Color.blue.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            VStack(alignment: .center, spacing: 2) {
                HStack(spacing: 2) {
                    TextField("--", value: displayWeight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 56)
                    Text(unit.symbol)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let prev = previousWeight {
                    Text("\(unit.fromKgRounded(prev), specifier: "%.1f")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text("x")
                .foregroundStyle(.secondary)

            VStack(alignment: .center, spacing: 2) {
                TextField("--", value: $reps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 48)
                if let prev = previousReps {
                    Text("\(prev)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .center, spacing: 2) {
                TextField("RPE", value: $rpe, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 48)
                Text("RPE")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
