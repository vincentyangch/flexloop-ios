import Foundation
import HealthKit

actor HealthKitManager {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()
    private var isAuthorized = false

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isAvailable else { return }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        ]

        let writeTypes: Set<HKSampleType> = [
            HKObjectType.workoutType(),
        ]

        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        isAuthorized = true
    }

    func fetchLatestHeartRate() async -> Double? {
        guard isAvailable else { return nil }

        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate, ascending: false
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let bpm = sample.quantity.doubleValue(
                    for: HKUnit.count().unitDivided(by: .minute())
                )
                continuation.resume(returning: bpm)
            }
            healthStore.execute(query)
        }
    }

    func saveWorkout(startDate: Date, endDate: Date, caloriesBurned: Double?) async throws {
        guard isAvailable, isAuthorized else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining

        let builder = HKWorkoutBuilder(
            healthStore: healthStore, configuration: config, device: .local()
        )
        try await builder.beginCollection(at: startDate)

        if let calories = caloriesBurned {
            let energySample = HKQuantitySample(
                type: HKQuantityType(.activeEnergyBurned),
                quantity: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
                start: startDate,
                end: endDate
            )
            try await builder.addSamples([energySample])
        }

        try await builder.endCollection(at: endDate)
        try await builder.finishWorkout()
    }
}
