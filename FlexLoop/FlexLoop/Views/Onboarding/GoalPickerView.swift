import SwiftUI
import SwiftData

struct GoalPickerView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.modelContext) private var context

    var body: some View {
        Form {
            Section("Primary Goal") {
                Picker("Goal", selection: $viewModel.goals) {
                    ForEach(viewModel.goalOptions, id: \.self) { Text($0.capitalized) }
                }
                .pickerStyle(.inline)
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            Section {
                Button {
                    Task {
                        await viewModel.submit(apiClient: APIClient(config: .current), context: context)
                    }
                } label: {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Create Profile & Generate Plan")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(viewModel.isSubmitting)
            }
        }
    }
}
