import Foundation
import Observation

struct ExerciseDetail {
    let name: String
    let muscleGroup: String
    let equipment: String
    let category: String
    let difficulty: String
    let description: String
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let instructions: [String]
    let formCues: [String]
    let commonMistakes: [String]
    let breathing: String
    let demoURL: String?
}

@Observable
final class ExerciseDetailViewModel {
    var detail: ExerciseDetail?
    var isLoading = false
    var errorMessage: String?
    var currentInstructionStep = 0

    func loadExercise(apiClient: APIClient, exerciseId: Int) async {
        isLoading = true

        struct ExResponse: Codable {
            let id: Int
            let name: String
            let muscleGroup: String
            let equipment: String
            let category: String
            let difficulty: String
            let metadataJson: MetadataJson?

            enum CodingKeys: String, CodingKey {
                case id, name, equipment, category, difficulty
                case muscleGroup = "muscle_group"
                case metadataJson = "metadata_json"
            }
        }

        struct MetadataJson: Codable {
            let description: String?
            let primaryMuscles: [String]?
            let secondaryMuscles: [String]?
            let instructions: [String]?
            let formCues: [String]?
            let commonMistakes: [String]?
            let breathing: String?
            let demoUrl: String?

            enum CodingKeys: String, CodingKey {
                case description, instructions, breathing
                case primaryMuscles = "primary_muscles"
                case secondaryMuscles = "secondary_muscles"
                case formCues = "form_cues"
                case commonMistakes = "common_mistakes"
                case demoUrl = "demo_url"
            }
        }

        do {
            let response: ExResponse = try await apiClient.get("/api/exercises/\(exerciseId)")
            let meta = response.metadataJson

            detail = ExerciseDetail(
                name: response.name,
                muscleGroup: response.muscleGroup,
                equipment: response.equipment,
                category: response.category,
                difficulty: response.difficulty,
                description: meta?.description ?? "",
                primaryMuscles: meta?.primaryMuscles ?? [response.muscleGroup],
                secondaryMuscles: meta?.secondaryMuscles ?? [],
                instructions: meta?.instructions ?? [],
                formCues: meta?.formCues ?? [],
                commonMistakes: meta?.commonMistakes ?? [],
                breathing: meta?.breathing ?? "",
                demoURL: meta?.demoUrl
            )
        } catch {
            errorMessage = "Could not load exercise details."
        }

        isLoading = false
    }

    func nextStep() {
        guard let detail else { return }
        if currentInstructionStep < detail.instructions.count - 1 {
            currentInstructionStep += 1
        }
    }

    func previousStep() {
        if currentInstructionStep > 0 {
            currentInstructionStep -= 1
        }
    }
}
