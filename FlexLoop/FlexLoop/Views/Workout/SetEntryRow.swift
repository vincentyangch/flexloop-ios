import SwiftUI

struct SetEntryRow: View {
    let setNumber: Int
    let previousWeight: Double?
    let previousReps: Int?

    @Binding var weight: Double?
    @Binding var reps: Int?
    @Binding var rpe: Double?
    @Binding var setType: SetType

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
                TextField("--", value: $weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 64)
                if let prev = previousWeight {
                    Text("\(prev, specifier: "%.1f")")
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
