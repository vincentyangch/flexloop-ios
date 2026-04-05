import SwiftUI

@Observable
class PlanRefinerViewModel {
    // MARK: - Swap State
    var alternatives: [APISwapAlternative] = []
    var originalExercise: APIOriginalExercise?
    var isLoadingSwap = false

    // MARK: - Volume State
    var volumeChanges: [APIPlanChange] = []
    var isLoadingVolume = false

    // MARK: - Explain State
    var explanation: String?
    var isLoadingExplain = false

    // MARK: - Refine Chat State
    var refineReply: String?
    var refineChanges: [APIPlanChange] = []
    var isLoadingRefine = false
    var chatHistory: [[String: String]] = []

    // MARK: - Shared
    var errorMessage: String?

    /// True when any refinement action is in-flight — used to disable concurrent actions.
    var isAnyActionLoading: Bool {
        isLoadingSwap || isLoadingVolume || isLoadingExplain || isLoadingRefine
    }

    // MARK: - Actions

    func suggestSwap(
        apiClient: APIClient, planId: Int, userId: Int,
        dayNumber: Int, exerciseName: String
    ) async {
        isLoadingSwap = true
        errorMessage = nil
        do {
            let response = try await apiClient.suggestSwap(
                planId: planId,
                body: APISuggestSwapRequest(
                    userId: userId, dayNumber: dayNumber, exerciseName: exerciseName
                )
            )
            if response.status == "success" {
                alternatives = response.alternatives ?? []
                originalExercise = response.original
            } else {
                errorMessage = response.message ?? String(localized: "error.suggestSwap")
            }
        } catch {
            errorMessage = String(localized: "error.suggestSwap")
        }
        isLoadingSwap = false
    }

    func adjustVolume(
        apiClient: APIClient, planId: Int, userId: Int,
        dayNumber: Int, direction: String
    ) async {
        isLoadingVolume = true
        errorMessage = nil
        do {
            let response = try await apiClient.adjustVolume(
                planId: planId,
                body: APIAdjustVolumeRequest(
                    userId: userId, dayNumber: dayNumber, direction: direction
                )
            )
            if response.status == "success" {
                volumeChanges = response.changes ?? []
            } else {
                errorMessage = response.message ?? String(localized: "error.adjustVolume")
            }
        } catch {
            errorMessage = String(localized: "error.adjustVolume")
        }
        isLoadingVolume = false
    }

    func explainExercise(
        apiClient: APIClient, planId: Int, userId: Int,
        dayNumber: Int, exerciseName: String
    ) async {
        isLoadingExplain = true
        errorMessage = nil
        do {
            let response = try await apiClient.explainExercise(
                planId: planId,
                body: APIExplainRequest(
                    userId: userId, dayNumber: dayNumber, exerciseName: exerciseName
                )
            )
            if response.status == "success" {
                explanation = response.explanation
            } else {
                errorMessage = response.message ?? String(localized: "error.explain")
            }
        } catch {
            errorMessage = String(localized: "error.explain")
        }
        isLoadingExplain = false
    }

    func refinePlan(
        apiClient: APIClient, planId: Int, userId: Int, message: String
    ) async {
        isLoadingRefine = true
        errorMessage = nil
        chatHistory.append(["role": "user", "content": message])
        do {
            let response = try await apiClient.refinePlan(
                planId: planId,
                body: APIPlanRefineRequest(
                    userId: userId, message: message, history: chatHistory
                )
            )
            if response.status == "success" {
                refineReply = response.reply
                refineChanges = response.changes ?? []
                if let reply = response.reply {
                    chatHistory.append(["role": "assistant", "content": reply])
                }
            } else {
                errorMessage = response.message ?? String(localized: "error.refine")
            }
        } catch {
            errorMessage = String(localized: "error.refine")
        }
        isLoadingRefine = false
    }

    // MARK: - Clear / Reset

    func clearSwap() {
        alternatives = []
        originalExercise = nil
    }

    func clearVolume() {
        volumeChanges = []
    }

    func clearExplanation() {
        explanation = nil
    }

    func clearRefine() {
        refineReply = nil
        refineChanges = []
    }

    func resetChat() {
        chatHistory = []
        refineReply = nil
        refineChanges = []
    }
}
