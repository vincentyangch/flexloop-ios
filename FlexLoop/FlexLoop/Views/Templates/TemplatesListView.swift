import SwiftUI
import SwiftData

struct TemplatesListView: View {
    @Query private var users: [CachedUser]
    @State private var viewModel = TemplatesViewModel()
    @State private var showCreateSheet = false
    @State private var selectedTemplate: APITemplate?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading templates...")
                } else if viewModel.templates.isEmpty {
                    ContentUnavailableView {
                        Label("No Templates", systemImage: "doc.on.doc")
                    } description: {
                        Text("Save a workout as a template to reuse it later.")
                    } actions: {
                        Button("Create Template") { showCreateSheet = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    templatesList
                }
            }
            .navigationTitle("Templates")
            .toolbar {
                if !viewModel.templates.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showCreateSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateTemplateView(viewModel: viewModel)
            }
            .fullScreenCover(item: $selectedTemplate) { template in
                ActiveWorkoutView(templateExercises: template.exercisesJson)
            }
            .task {
                guard let user = users.first else { return }
                let apiClient = APIClient(config: .current)
                await viewModel.loadTemplates(apiClient: apiClient, userId: user.serverId)
            }
        }
    }

    private var templatesList: some View {
        List {
            ForEach(viewModel.templates) { template in
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)

                    let exerciseCount = template.exercisesJson.count
                    Text("\(exerciseCount) exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    let names = template.exercisesJson.compactMap {
                        $0["exercise_name"]?.stringValue
                    }
                    if !names.isEmpty {
                        Text(names.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }

                    Button {
                        selectedTemplate = template
                    } label: {
                        Label("Start Workout", systemImage: "play.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.small)
                    .padding(.top, 4)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task {
                            let apiClient = APIClient(config: .current)
                            await viewModel.deleteTemplate(apiClient: apiClient,
                                                           templateId: template.id)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}
