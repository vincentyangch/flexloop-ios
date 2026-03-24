import SwiftUI

struct EquipmentPickerView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void

    var body: some View {
        Form {
            Section("Available Equipment") {
                Text("Select what you have access to:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(viewModel.equipmentOptions, id: \.self) { item in
                    Button {
                        if viewModel.availableEquipment.contains(item) {
                            viewModel.availableEquipment.remove(item)
                        } else {
                            viewModel.availableEquipment.insert(item)
                        }
                    } label: {
                        HStack {
                            Text(item.replacingOccurrences(of: "_", with: " ").capitalized)
                            Spacer()
                            if viewModel.availableEquipment.contains(item) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }

            Section {
                Button("Next") { onNext() }
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
