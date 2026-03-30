import SwiftUI

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @State private var currentStep = 0

    var body: some View {
        NavigationStack {
            TabView(selection: $currentStep) {
                ProfileSetupView(viewModel: viewModel, onNext: { currentStep = 1 })
                    .tag(0)
                GoalPickerView(viewModel: viewModel)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .navigationTitle("Welcome to FlexLoop")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
