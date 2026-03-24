import SwiftUI

struct ProfileSetupView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void

    var body: some View {
        Form {
            Section("About You") {
                TextField("Name", text: $viewModel.name)

                Picker("Gender", selection: $viewModel.gender) {
                    ForEach(viewModel.genders, id: \.self) { Text($0.capitalized) }
                }

                Stepper("Age: \(viewModel.age)", value: $viewModel.age, in: 13...100)

                HStack {
                    Text("Height")
                    Spacer()
                    TextField("cm", value: $viewModel.heightCm, format: .number)
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                    Text("cm")
                }

                HStack {
                    Text("Weight")
                    Spacer()
                    TextField("kg", value: $viewModel.weightKg, format: .number)
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                    Text("kg")
                }
            }

            Section("Experience") {
                Picker("Level", selection: $viewModel.experienceLevel) {
                    ForEach(viewModel.experienceLevels, id: \.self) { Text($0.capitalized) }
                }

                Stepper("Days per week: \(viewModel.daysPerWeek)",
                        value: $viewModel.daysPerWeek, in: 1...7)
            }

            Section {
                Button("Next") { onNext() }
                    .frame(maxWidth: .infinity)
                    .disabled(viewModel.name.isEmpty)
            }
        }
    }
}
