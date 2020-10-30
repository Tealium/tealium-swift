//
//  MigratorTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class MigratorTests: XCTestCase {

    var config: TealiumConfig!
    var migrator: Migrator!
    var tealium: Tealium!

    let mockMigrator = MockMigrator()

    let mockUserDefaultsConsent = MockUserDefaultsConsent()
    let mockUnarchiverConsent = MockUnarchiverConsent()
    let mockUserDefaultsConsentNoData = MockLegacyUserDefaultsNoData()
    let mockUnarchiverConsentNoData = MockUnarchiverConsentNoData()

    let mockLegacyUserDefaults = MockLegacyUserDefaults()
    let mockLegacyUserDefaultsNoData = MockLegacyUserDefaultsNoData()

    override func setUpWithError() throws {
        config = TealiumConfig(account: "testaccount", profile: "testprofile", environment: "testenvironment")
    }

    func testExtractConsentPreferences_userDefaults_objectMethodRun() {
        migrator = Migrator(config: config, userDefaults: mockUserDefaultsConsent, unarchiver: mockUnarchiverConsent)
        _ = migrator.extractConsentPreferences()
        XCTAssertEqual(mockUserDefaultsConsent.objectCount, 1)
    }

    func testExtractConsentPreferences_userDefaults_objectMethodNotRunWithNoData() {
        migrator = Migrator(config: config, userDefaults: mockUserDefaultsConsentNoData, unarchiver: mockUnarchiverConsent)
        _ = migrator.extractConsentPreferences()
        XCTAssertEqual(mockUserDefaultsConsent.objectCount, 0)
    }

    func testExtractConsentPreferences_userDefaults_removeMethodRun() {
        migrator = Migrator(config: config, userDefaults: mockUserDefaultsConsent, unarchiver: mockUnarchiverConsent)
        _ = migrator.extractConsentPreferences()
        XCTAssertEqual(mockUserDefaultsConsent.removeCount, 1)
    }

    func testExtractConsentPreferences_userDefaults_removeMethodNotRunWithNoData() {
        migrator = Migrator(config: config, userDefaults: mockUserDefaultsConsentNoData, unarchiver: mockUnarchiverConsent)
        _ = migrator.extractConsentPreferences()
        XCTAssertEqual(mockUserDefaultsConsent.removeCount, 0)
    }

    func testExtractConsentPreferences_unarchiver_setClassMethodRun() {
        migrator = Migrator(config: config, userDefaults: mockUserDefaultsConsent, unarchiver: mockUnarchiverConsent)
        _ = migrator.extractConsentPreferences()
        XCTAssertEqual(mockUnarchiverConsent.setClassCount, 1)
    }

    func testExtractConsentPreferences_unarchiver_setClassMethodNotRunWithNoData() {
        migrator = Migrator(config: config, userDefaults: mockUserDefaultsConsentNoData, unarchiver: mockUnarchiverConsent)
        _ = migrator.extractConsentPreferences()
        XCTAssertEqual(mockUnarchiverConsent.setClassCount, 0)
    }

    func testExtractConsentPreferences_unarchiver_unarchiveMethodRun() {
        MockUnarchiverConsent.unarchiveCount = 0
        migrator = Migrator(config: config, userDefaults: mockUserDefaultsConsent, unarchiver: mockUnarchiverConsent)
        _ = migrator.extractConsentPreferences()
        XCTAssertEqual(MockUnarchiverConsent.unarchiveCount, 1)
    }

    func testExtractConsentPreferences_unarchiver_unarchiveMethodNotRunWithNoData() {
        MockUnarchiverConsent.unarchiveCount = 0
        migrator = Migrator(config: config, userDefaults: mockUserDefaultsConsentNoData, unarchiver: mockUnarchiverConsent)
        _ = migrator.extractConsentPreferences()
        XCTAssertEqual(MockUnarchiverConsent.unarchiveCount, 0)
    }

    func testExtractConsentPreferences_returnsDataFromLegacyStorage() {
        migrator = Migrator(config: config, userDefaults: mockUserDefaultsConsent, unarchiver: mockUnarchiverConsent)
        let expected: [String: Any] = [ConsentKey.consentStatus: 1,
                                       ConsentKey.consentCategoriesKey: [TealiumConsentCategories.affiliates.rawValue,
                                                                         TealiumConsentCategories.bigData.rawValue,
                                                                         TealiumConsentCategories.crm.rawValue,
                                                                         TealiumConsentCategories.engagement.rawValue],
                                       ConsentKey.consentLoggingEnabled: true]
        let actual = migrator.extractConsentPreferences()
        XCTAssertTrue(actual.equal(to: expected))
    }

    func testExtractConsentPreferences_returnsEmptyDictionary_noUserDefaultsData() {
        migrator = Migrator(config: config, userDefaults: mockUserDefaultsConsentNoData, unarchiver: mockUnarchiverConsent)
        let actual = migrator.extractConsentPreferences()
        XCTAssertTrue(actual.equal(to: [String: Any]()))
    }

    func testExtractConsentPreferences_returnsEmptyDictionary_noConsentConfigurationData() {
        migrator = Migrator(config: config, userDefaults: mockUserDefaultsConsent, unarchiver: mockUnarchiverConsentNoData)
        let actual = migrator.extractConsentPreferences()
        XCTAssertTrue(actual.equal(to: [String: Any]()))
    }

    func testExtractLifecycleData_returnsDataFromLegacyStorage() {
        migrator = Migrator(config: config, userDefaults: mockLegacyUserDefaults, unarchiver: mockUnarchiverConsent)
        let expected: [String: Any] = [LifecycleKey.migratedLifecycle:
                                        [LifecycleKey.firstLaunchDate: "2020-10-12T18:22:12Z",
                                         LifecycleKey.firstLaunchDateMMDDYYYY: "10/12/2020",
                                         LifecycleKey.lastLaunchDate: "2020-10-12T18:22:22Z",
                                         LifecycleKey.lastWakeDate: "2020-10-12T17:02:04Z",
                                         LifecycleKey.launchCount: 12,
                                         LifecycleKey.priorSecondsAwake: 10,
                                         LifecycleKey.sleepCount: 5,
                                         LifecycleKey.totalCrashCount: 2,
                                         LifecycleKey.totalLaunchCount: 12,
                                         LifecycleKey.totalSecondsAwake: 3000,
                                         LifecycleKey.totalSleepCount: 8,
                                         LifecycleKey.totalWakeCount: 7,
                                         LifecycleKey.wakeCount: 7],
                                       TealiumKey.visitorId: "205CA6D0FE3A4242A3522DBE7F5B75DE",
                                       TealiumKey.uuid: "205CA6D0-FE3A-4242-A352-2DBE7F5B75DE",
                                       "custom_persistent_key": "customValue"]
        let actual = migrator.extractLifecycleData(from: MockLegacyUserDefaults.mockData)
        XCTAssertTrue(actual.equal(to: expected))
    }

    func testExtractLifecycleData_returnsEmptyDictionary() {
        migrator = Migrator(config: config, userDefaults: mockLegacyUserDefaults, unarchiver: mockUnarchiverConsent)
        let actual = migrator.extractLifecycleData(from: [String: Any]())
        XCTAssertTrue(actual.equal(to: [String: Any]()))
    }

    func testExtractUserDefaults_userDefaults_objectMethodRun() {
        migrator = Migrator(config: config, userDefaults: mockLegacyUserDefaults, unarchiver: mockUnarchiverConsent)
        _ = migrator.extractUserDefaults()
        XCTAssertEqual(mockLegacyUserDefaults.objectCount, 1)
    }

    func testExtractUserDefaults_userDefaults_objectMethodNotRunWithNoData() {
        migrator = Migrator(config: config, userDefaults: mockUserDefaultsConsentNoData, unarchiver: mockUnarchiverConsent)
        _ = migrator.extractUserDefaults()
        XCTAssertEqual(mockLegacyUserDefaults.objectCount, 0)
    }

    func testExtractUserDefaults_userDefaults_removeMethodRun() {
        migrator = Migrator(config: config, userDefaults: mockLegacyUserDefaults, unarchiver: mockUnarchiverConsent)
        _ = migrator.extractUserDefaults()
        XCTAssertEqual(mockLegacyUserDefaults.removeCount, 1)
    }

    func testExtractUserDefaults_userDefaults_removeMethodNotRunWithNoData() {
        migrator = Migrator(config: config, userDefaults: mockLegacyUserDefaultsNoData, unarchiver: mockUnarchiverConsent)
        _ = migrator.extractUserDefaults()
        XCTAssertEqual(mockLegacyUserDefaults.removeCount, 0)
    }

    func testExtractUserDefaults_returnsDataFromLegacyStorage() {
        migrator = Migrator(config: config, userDefaults: mockLegacyUserDefaults, unarchiver: mockUnarchiverConsent)

        let expected: [String: Any] = [LifecycleKey.migratedLifecycle:
                                        [LifecycleKey.firstLaunchDate: "2020-10-12T18:22:12Z",
                                         LifecycleKey.firstLaunchDateMMDDYYYY: "10/12/2020",
                                         LifecycleKey.lastLaunchDate: "2020-10-12T18:22:22Z",
                                         LifecycleKey.lastWakeDate: "2020-10-12T17:02:04Z",
                                         LifecycleKey.launchCount: 12,
                                         LifecycleKey.priorSecondsAwake: 10,
                                         LifecycleKey.sleepCount: 5,
                                         LifecycleKey.totalCrashCount: 2,
                                         LifecycleKey.totalLaunchCount: 12,
                                         LifecycleKey.totalSecondsAwake: 3000,
                                         LifecycleKey.totalSleepCount: 8,
                                         LifecycleKey.totalWakeCount: 7,
                                         LifecycleKey.wakeCount: 7],
                                       TealiumKey.visitorId: "205CA6D0FE3A4242A3522DBE7F5B75DE",
                                       TealiumKey.uuid: "205CA6D0-FE3A-4242-A352-2DBE7F5B75DE",
                                       "custom_persistent_key": "customValue"]

        let actual = migrator.extractUserDefaults()

        XCTAssertTrue(actual.equal(to: expected))
    }

    func testExtractUserDefaults_returnsEmptyDictionary() {
        migrator = Migrator(config: config, userDefaults: mockLegacyUserDefaultsNoData, unarchiver: mockUnarchiverConsent)
        let actual = migrator.extractUserDefaults()
        XCTAssertTrue(actual.equal(to: [String: Any]()))
    }

    func testMigratePersistent_dataLayer_addMethodRun() {
        migrator = Migrator(config: config, userDefaults: mockLegacyUserDefaults, unarchiver: mockUnarchiverConsent)
        let dummyDataLayer = DummyDataManager()
        migrator.migratePersistent(dataLayer: dummyDataLayer)
        XCTAssertEqual(dummyDataLayer.addCount, 1)
    }

    func testMigratePersistent_methodRunUponTealiumInit_migrateFlagTrue() {
        config.shouldMigratePersistentData = true
        tealium = Tealium(config: config, dataLayer: DummyDataManager(), modulesManager: nil, migrator: mockMigrator, enableCompletion: { _ in })
        XCTAssertEqual(mockMigrator.migrateCount, 1)
    }

    func testMigratePersistent_methodNotRunUponTealiumInit_migrateFlagDefault() {
        tealium = Tealium(config: config, dataLayer: DummyDataManager(), modulesManager: nil, migrator: mockMigrator, enableCompletion: { _ in })
        XCTAssertEqual(mockMigrator.migrateCount, 0)
    }

    func testMigratePersistent_methodNotRunUponTealiumInit_migrateFlagFalse() {
        config.shouldMigratePersistentData = false
        tealium = Tealium(config: config, dataLayer: DummyDataManager(), modulesManager: nil, migrator: mockMigrator, enableCompletion: { _ in })
        XCTAssertEqual(mockMigrator.migrateCount, 0)
    }

}

fileprivate extension Dictionary where Key == String, Value == Any {
    func equal(to dictionary: [String: Any] ) -> Bool {
        NSDictionary(dictionary: self).isEqual(to: dictionary)
    }
}
