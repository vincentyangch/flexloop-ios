import SwiftUI

struct ProfileSetupView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void

    var body: some View {
        Form {
            Section(String(localized: "onboarding.unitSystem")) {
                Picker("", selection: $viewModel.weightUnit) {
                    Text("kg").tag(WeightUnit.kg)
                    Text("lbs").tag(WeightUnit.lbs)
                }
                .pickerStyle(.segmented)
            }

            Section("About You") {
                TextField("Name", text: $viewModel.name)

                Picker("Gender", selection: $viewModel.gender) {
                    ForEach(viewModel.genders, id: \.self) { Text($0.capitalized) }
                }

                Stepper("Age: \(viewModel.age)", value: $viewModel.age, in: 13...100)

                HStack {
                    Text("Height")
                    Spacer()
                    TextField(viewModel.weightUnit.heightSymbol, value: $viewModel.height, format: .number)
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                    Text(viewModel.weightUnit.heightSymbol)
                }

                HStack {
                    Text("Weight")
                    Spacer()
                    TextField(viewModel.weightUnit.symbol, value: $viewModel.weight, format: .number)
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                    Text(viewModel.weightUnit.symbol)
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
