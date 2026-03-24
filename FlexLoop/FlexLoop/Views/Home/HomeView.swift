import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Weekly streak card
                    HStack {
                        VStack(alignment: .leading) {
                            Text("This Week")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(viewModel.weeklySessionCount) sessions")
                                .font(.title2.bold())
                        }
                        Spacer()
                        Image(systemName: "flame.fill")
                            .font(.title)
                            .foregroundStyle(.orange)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Quick start button
                    NavigationLink {
                        ActiveWorkoutView()
                    } label: {
                        Label("Start Workout", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Templates shortcut
                    NavigationLink {
                        TemplatesListView()
                    } label: {
                        Label("My Templates", systemImage: "doc.on.doc")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .foregroundStyle(.primary)

                    // Recent sessions
                    if !viewModel.recentSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent Sessions")
                                .font(.headline)

                            ForEach(viewModel.recentSessions, id: \.startedAt) { session in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(session.source.rawValue
                                            .replacingOccurrences(of: "_", with: " ").capitalized)
                                            .font(.subheadline.bold())
                                        Text(session.startedAt, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("\(session.sets?.count ?? 0) sets")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("FlexLoop")
            .onAppear { viewModel.loadDashboard(context: context) }
        }
    }
}
