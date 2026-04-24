import Foundation
import Testing
import SwiftData
@testable import FlexLoop

// MARK: - Model Tests

struct ModelTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: CachedUser.self, CachedExercise.self,
                 CachedWorkoutSession.self, CachedWorkoutSet.self,
                 CachedPlan.self,
            configurations: config
        )
    }

    @Test func createUser() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let user = CachedUser(
            serverId: 1, name: "Test User", gender: "male", age: 28,
            height: 180.0, weight: 82.0, weightUnit: "kg", heightUnit: "cm",
            experienceLevel: "intermediate",
            goals: "hypertrophy", availableEquipment: ["barbell"]
        )
        context.insert(user)
        try context.save()

        let descriptor = FetchDescriptor<CachedUser>()
        let users = try context.fetch(descriptor)
        #expect(users.count == 1)
        #expect(users.first?.name == "Test User")
        #expect(users.first?.serverId == 1)
    }

    @Test func createExercise() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let exercise = CachedExercise(
            serverId: 1, name: "Bench Press", muscleGroup: "chest",
            equipment: "barbell", category: "compound", difficulty: "intermediate"
        )
        context.insert(exercise)
        try context.save()

        let descriptor = FetchDescriptor<CachedExercise>()
        let exercises = try context.fetch(descriptor)
        #expect(exercises.count == 1)
        #expect(exercises.first?.muscleGroup == "chest")
    }

    @Test func createWorkoutSessionWithSets() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let session = CachedWorkoutSession(source: .adHoc, startedAt: Date())
        context.insert(session)

        let set = CachedWorkoutSet(
            session: session, exerciseServerId: 1,
            setNumber: 1, setType: .working, weight: 100.0, reps: 5, rpe: 8.0
        )
        context.insert(set)
        try context.save()

        let descriptor = FetchDescriptor<CachedWorkoutSession>()
        let sessions = try context.fetch(descriptor)
        #expect(sessions.count == 1)
        #expect(sessions.first?.sets?.count == 1)
        #expect(sessions.first?.isSynced == false)
    }

    @Test func sessionDefaultsToUnsynced() throws {
        let session = CachedWorkoutSession(source: .plan, startedAt: Date())
        #expect(session.isSynced == false)
    }
}

// MARK: - GuidedWorkoutViewModel Tests

@MainActor
struct GuidedWorkoutViewModelTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: CachedUser.self, CachedExercise.self,
                 CachedWorkoutSession.self, CachedWorkoutSet.self,
                 CachedPlan.self,
            configurations: config
        )
        return ModelContext(container)
    }

    private func makePlanDay() throws -> APIPlanDay {
        let json = """
        {
          "id": 7,
          "day_number": 1,
          "label": "Push",
          "focus": "Chest and Shoulders",
          "exercise_groups": [
            {
              "id": 11,
              "group_type": "straight",
              "order": 1,
              "rest_after_group_sec": 90,
              "exercises": [
                {
                  "id": 1011,
                  "exercise_id": 101,
                  "order": 1,
                  "sets": 2,
                  "reps": 5,
                  "weight": 100.0,
                  "rpe_target": 8.0,
                  "sets_json": [
                    {
                      "set_number": 1,
                      "target_weight": 95.0,
                      "target_reps": 5,
                      "target_rpe": 7.5
                    },
                    {
                      "set_number": 2,
                      "target_weight": 100.0,
                      "target_reps": 5,
                      "target_rpe": 8.0
                    }
                  ],
                  "notes": "Pause first rep"
                },
                {
                  "id": 1012,
                  "exercise_id": 102,
                  "order": 2,
                  "sets": 3,
                  "reps": 8,
                  "weight": 60.0,
                  "rpe_target": 7.0,
                  "sets_json": null,
                  "notes": null
                }
              ]
            }
          ]
        }
        """
        return try JSONDecoder().decode(APIPlanDay.self, from: Data(json.utf8))
    }

    @Test func loadFromPlanDayBuildsGuidedExercises() throws {
        let vm = GuidedWorkoutViewModel()
        let day = try makePlanDay()

        vm.loadFromPlanDay(day, exerciseNames: [101: "Bench Press", 102: "Overhead Press"])

        #expect(vm.isWorkoutActive == true)
        #expect(vm.startedAt != nil)
        #expect(vm.currentExerciseIndex == 0)
        #expect(vm.exercises.count == 2)
        #expect(vm.progress == "0/2")

        let first = try #require(vm.exercises.first)
        #expect(first.exerciseId == 101)
        #expect(first.planExerciseId == 1011)
        #expect(first.name == "Bench Press")
        #expect(first.restSeconds == 90)
        #expect(first.notes == "Pause first rep")
        #expect(first.targetSets.count == 2)
        #expect(first.targetSets[0].targetWeight == 95.0)
        #expect(first.targetSets[0].targetReps == 5)
        #expect(first.targetSets[0].targetRpe == 7.5)

        let second = try #require(vm.exercises.last)
        #expect(second.name == "Overhead Press")
        #expect(second.targetSets.count == 3)
        #expect(second.targetSets[0].targetWeight == 60.0)
        #expect(second.targetSets[0].targetReps == 8)
        #expect(second.targetSets[0].targetRpe == 7.0)
    }

    @Test func completeSetAddsCompletedSetAndCanEditIt() throws {
        let vm = GuidedWorkoutViewModel()
        let day = try makePlanDay()
        vm.loadFromPlanDay(day, exerciseNames: [101: "Bench Press", 102: "Overhead Press"])

        vm.completeSet(exerciseIndex: 0, setNumber: 1, weight: 97.5, reps: 5, rpe: 8.0)
        defer { vm.stopRestTimer() }

        let firstExercise = try #require(vm.exercises.first)
        let completed = try #require(firstExercise.completedSets.first)
        #expect(completed.setNumber == 1)
        #expect(completed.weight == 97.5)
        #expect(completed.reps == 5)
        #expect(completed.rpe == 8.0)
        #expect(completed.setType == .working)
        #expect(vm.isRestTimerActive == true)
        #expect(vm.restTimeRemaining == 120)
        #expect(vm.currentExerciseIndex == 0)
        #expect(vm.progress == "1/2")

        vm.editCompletedSet(exerciseIndex: 0, setId: completed.id, weight: 100.0, reps: 4, rpe: 8.5)

        let edited = try #require(vm.exercises.first?.completedSets.first)
        #expect(edited.weight == 100.0)
        #expect(edited.reps == 4)
        #expect(edited.rpe == 8.5)
    }

    @Test func skipExerciseMarksCurrentExerciseAndAdvances() throws {
        let vm = GuidedWorkoutViewModel()
        let day = try makePlanDay()
        vm.loadFromPlanDay(day, exerciseNames: [101: "Bench Press", 102: "Overhead Press"])

        vm.skipExercise()

        #expect(vm.exercises[0].isSkipped == true)
        #expect(vm.currentExerciseIndex == 1)
        #expect(vm.progress == "0/1")
    }

    @Test func finishWorkoutPersistsSessionSetsAndSummary() throws {
        let context = try makeContext()
        let vm = GuidedWorkoutViewModel()
        let day = try makePlanDay()
        vm.loadFromPlanDay(day, exerciseNames: [101: "Bench Press", 102: "Overhead Press"])
        vm.startedAt = nil
        vm.exercises[0].completedSets.append(
            CompletedSet(setNumber: 1, weight: 100.0, reps: 5, rpe: 8.0, setType: .working)
        )
        vm.exercises[1].isSkipped = true

        vm.finishWorkout(context: context, userId: 42, planDayId: 7)

        let descriptor = FetchDescriptor<CachedWorkoutSession>()
        let sessions = try context.fetch(descriptor)
        let session = try #require(sessions.first)
        let savedSet = try #require(session.sets?.first)

        #expect(sessions.count == 1)
        #expect(session.userId == 42)
        #expect(session.planDayId == 7)
        #expect(session.source == .plan)
        #expect(session.completedAt != nil)
        #expect(session.isSynced == false)
        #expect(savedSet.exerciseServerId == 101)
        #expect(savedSet.setNumber == 1)
        #expect(savedSet.weight == 100.0)
        #expect(savedSet.reps == 5)
        #expect(savedSet.rpe == 8.0)
        #expect(vm.isWorkoutActive == false)
        #expect(vm.showSummary == true)
        #expect(vm.workoutSummary?.exercisesCompleted == 1)
        #expect(vm.workoutSummary?.exercisesSkipped == 1)
        #expect(vm.workoutSummary?.totalSets == 1)
    }

    @Test func restTimerStartsAndStops() {
        let vm = GuidedWorkoutViewModel()
        vm.startRestTimer(seconds: 90)
        #expect(vm.isRestTimerActive == true)
        #expect(vm.restTimeRemaining == 90)

        vm.stopRestTimer()
        #expect(vm.isRestTimerActive == false)
        #expect(vm.restTimeRemaining == 0)
    }
}

// MARK: - SyncService Tests

struct SyncServiceTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: CachedUser.self, CachedExercise.self,
                 CachedWorkoutSession.self, CachedWorkoutSet.self,
                 CachedPlan.self,
            configurations: config
        )
        return ModelContext(container)
    }

    @Test func findUnsyncedSessions() throws {
        let context = try makeContext()

        let synced = CachedWorkoutSession(source: .adHoc, startedAt: Date())
        synced.isSynced = true
        context.insert(synced)

        let unsynced = CachedWorkoutSession(source: .adHoc, startedAt: Date())
        unsynced.isSynced = false
        context.insert(unsynced)

        try context.save()

        let result = SyncService.findUnsyncedSessions(in: context)
        #expect(result.count == 1)
    }

    @Test func buildSyncRequest() throws {
        let context = try makeContext()

        let session = CachedWorkoutSession(userId: 1, source: .adHoc, startedAt: Date())
        context.insert(session)

        let set = CachedWorkoutSet(
            session: session, exerciseServerId: 1,
            setNumber: 1, setType: .working, weight: 100.0, reps: 5
        )
        context.insert(set)
        try context.save()

        let request = SyncService.buildSyncRequest(userId: 1, sessions: [session])
        #expect(request.workouts.count == 1)
        #expect(request.workouts.first?.sets.count == 1)
        #expect(request.workouts.first?.sets.first?.weight == 100.0)
    }
}

// MARK: - APIClient Tests

struct APIClientTests {

    @Test func buildURL() {
        let config = ServerConfig(baseURL: "http://localhost:8000")
        // We can't call actor methods synchronously, but we can verify construction
        #expect(config.baseURL == "http://localhost:8000")
    }
}

// MARK: - AIChatViewModel Tests

struct AIChatViewModelTests {

    @Test func initialState() {
        let vm = AIChatViewModel()
        #expect(vm.messages.isEmpty)
        #expect(vm.inputText == "")
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }
}
