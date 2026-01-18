//
//  ParentSettings.swift
//  Sproutling
//
//  SwiftData model for app-wide parent settings
//

import Foundation
import SwiftData

@Model
final class ParentSettings {
    /// Whether PIN is required to access settings and profile management
    var requirePinForSettings: Bool = false

    /// Sound effects enabled
    var soundEnabled: Bool = true

    /// Haptic feedback enabled
    var hapticsEnabled: Bool = true

    /// Daily time limit enabled
    var timeLimitEnabled: Bool = false

    /// Daily time limit in minutes (default 30, range 5-60)
    var dailyTimeLimitMinutes: Int = 30

    /// Last sync timestamp
    var lastSyncDate: Date?

    /// Settings ID for singleton pattern (CloudKit doesn't support unique constraints)
    var settingsId: String = "main_settings"

    init() {
        // All properties have defaults above for CloudKit compatibility
    }

    // Note: PIN is stored in Keychain via KeychainManager, not in this model
}

// MARK: - Time Limit Options
enum TimeLimitOption: Int, CaseIterable, Identifiable {
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case twentyMinutes = 20
    case thirtyMinutes = 30
    case fortyFiveMinutes = 45
    case oneHour = 60

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .fiveMinutes: return "5 minutes"
        case .tenMinutes: return "10 minutes"
        case .fifteenMinutes: return "15 minutes"
        case .twentyMinutes: return "20 minutes"
        case .thirtyMinutes: return "30 minutes"
        case .fortyFiveMinutes: return "45 minutes"
        case .oneHour: return "1 hour"
        }
    }

    static func from(minutes: Int) -> TimeLimitOption {
        allCases.first { $0.rawValue == minutes } ?? .thirtyMinutes
    }
}

// MARK: - Sync Status
enum SyncStatus: Equatable {
    case idle
    case syncing
    case synced(Date)
    case error(String)

    var description: String {
        switch self {
        case .idle:
            return "Not synced"
        case .syncing:
            return "Syncing..."
        case .synced(let date):
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Synced \(formatter.localizedString(for: date, relativeTo: Date()))"
        case .error(let message):
            return "Sync error: \(message)"
        }
    }

    var iconName: String {
        switch self {
        case .idle:
            return "icloud.slash"
        case .syncing:
            return "arrow.triangle.2.circlepath.icloud"
        case .synced:
            return "checkmark.icloud"
        case .error:
            return "exclamationmark.icloud"
        }
    }
}
