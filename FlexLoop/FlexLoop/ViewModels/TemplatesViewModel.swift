import Foundation
import Observation

@Observable
final class TemplatesViewModel {
    var templates: [APITemplate] = []
    var isLoading = false
    var errorMessage: String?

    func loadTemplates(apiClient: APIClient, userId: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            templates = try await apiClient.fetchTemplates(userId: userId)
        } catch {
            errorMessage = "Could not load templates."
        }

        isLoading = false
    }

    func saveTemplate(apiClient: APIClient, userId: Int, name: String,
                      exercises: [TemplateExerciseEntry]) async {
        let exercisesJson = exercises.map { entry -> [String: AnyCodableValue] in
            var dict: [String: AnyCodableValue] = [
                "exercise_id": .int(entry.exerciseId),
                "exercise_name": .string(entry.exerciseName),
                "sets": .int(entry.sets),
                "reps": .int(entry.reps),
            ]
            if let weight = entry.weight {
                dict["weight"] = .double(weight)
            }
            return dict
        }

        let data = APITemplateCreate(userId: userId, name: name, exercisesJson: exercisesJson)

        do {
            let template = try await apiClient.createTemplate(data: data)
            templates.insert(template, at: 0)
        } catch {
            errorMessage = "Failed to save template."
        }
    }

    func deleteTemplate(apiClient: APIClient, templateId: Int) async {
        do {
            try await apiClient.deleteTemplate(id: templateId)
            templates.removeAll { $0.id == templateId }
        } catch {
            errorMessage = "Failed to delete template."
        }
    }
}

struct TemplateExerciseEntry: Identifiable {
    let id = UUID()
    var exerciseId: Int
    var exerciseName: String
    var sets: Int
    var reps: Int
    var weight: Double?
}
