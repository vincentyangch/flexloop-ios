import SwiftUI
import SwiftData
import Charts

struct ProgressTabView: View {
    @Query private var users: [CachedUser]
    @State private var viewModel = ProgressViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedTab) {
                    Text("Strength").tag(0)
                    Text("Volume").tag(1)
                    Text("History").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case 0: strengthView
                case 1: volumeView
                case 2: HistoryView()
                default: EmptyView()
                }
            }
            .navigationTitle("Progress")
            .task {
                guard let user = users.first else { return }
                let apiClient = APIClient(config: .current)
                await viewModel.loadProgress(apiClient: apiClient, userId: user.serverId)
            }
        }
    }

    private var strengthView: some View {
        Group {
            if viewModel.isLoading {
                SwiftUI.ProgressView("Loading...")
                    .frame(maxHeight: .infinity)
            } else if viewModel.e1rmData.isEmpty {
                ContentUnavailableView(
                    "No Strength Data",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Log some workouts to see your 1RM trends.")
                )
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(viewModel.e1rmData) { exercise in
                            E1RMChartCard(exercise: exercise)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var volumeView: some View {
        Group {
            if viewModel.isLoading {
                SwiftUI.ProgressView("Loading...")
                    .frame(maxHeight: .infinity)
            } else if viewModel.volumeData.isEmpty {
                ContentUnavailableView(
                    "No Volume Data",
                    systemImage: "chart.bar",
                    description: Text("Log some workouts to see your weekly volume.")
                )
            } else {
                ScrollView {
                    VolumeChartCard(data: viewModel.volumeData)
                        .padding()
                }
            }
        }
    }
}
