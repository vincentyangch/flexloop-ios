import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query private var users: [CachedUser]
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Deload alert banner
                    if let deload = viewModel.deloadAlert, deload.recommended {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
                                Text(String(localized: "home.deloadRecommended"))
                                    .font(.subheadline.bold())
                                Spacer()
                                Text(deload.confidence.uppercased())
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(deload.confidence == "high" ? Color.red.opacity(0.2) : Color.orange.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                            Text(deload.reason)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(deload.signals, id: \.self) { signal in
                                HStack(spacing: 4) {
                                    Circle().fill(.orange).frame(width: 4, height: 4)
                                    Text(signal).font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3)))
                    }

                    // Weekly streak card
                    HStack {
                        VStack(alignment: .leading) {
                            Text(String(localized: "home.thisWeek"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(String(localized: "home.sessions \(viewModel.weeklySessionCount)"))
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
                        Label(String(localized: "home.startWorkout"), systemImage: "play.fill")
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
                        Label(String(localized: "home.myTemplates"), systemImage: "doc.on.doc")
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
                            Text(String(localized: "home.recentSessions"))
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
            .task {
                guard let user = users.first else { return }
                let apiClient = APIClient(config: .current)
                await viewModel.checkDeload(apiClient: apiClient, userId: user.serverId)
            }
        }
    }
}
