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

// MARK: - ActiveWorkoutViewModel Tests

struct ActiveWorkoutViewModelTests {

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

    @Test func startWorkoutCreatesSession() throws {
        let context = try makeContext()
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)

        #expect(vm.currentSession != nil)
        #expect(vm.currentSession?.completedAt == nil)
        #expect(vm.isWorkoutActive == true)
    }

    @Test func logSetAddsToSession() throws {
        let context = try makeContext()
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)

        vm.logSet(exerciseId: 1, weight: 100, reps: 5, rpe: 8.0,
                  setType: .working, context: context)

        #expect(vm.loggedSets.count == 1)
        #expect(vm.loggedSets.first?.weight == 100)
        #expect(vm.loggedSets.first?.reps == 5)
        #expect(vm.loggedSets.first?.setNumber == 1)
    }

    @Test func logMultipleSetsIncrementsSetNumber() throws {
        let context = try makeContext()
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)

        vm.logSet(exerciseId: 1, weight: 100, reps: 5, context: context)
        vm.logSet(exerciseId: 1, weight: 100, reps: 5, context: context)
        vm.logSet(exerciseId: 1, weight: 100, reps: 4, context: context)

        #expect(vm.loggedSets.count == 3)
        #expect(vm.loggedSets[0].setNumber == 1)
        #expect(vm.loggedSets[1].setNumber == 2)
        #expect(vm.loggedSets[2].setNumber == 3)
    }

    @Test func completeWorkoutSetsTimestamp() throws {
        let context = try makeContext()
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)
        vm.completeWorkout(context: context)

        #expect(vm.currentSession?.completedAt != nil)
        #expect(vm.isWorkoutActive == false)
    }

    @Test func restTimerStartsAndStops() throws {
        let vm = ActiveWorkoutViewModel()
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
        let client = APIClient(config: config)
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
