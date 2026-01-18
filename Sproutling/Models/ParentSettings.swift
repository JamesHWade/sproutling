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

    /// Last sync timestamp
    var lastSyncDate: Date?

    /// Settings ID for singleton pattern (CloudKit doesn't support unique constraints)
    var settingsId: String = "main_settings"

    init() {
        // All properties have defaults above for CloudKit compatibility
    }

    // Note: PIN is stored in Keychain via KeychainManager, not in this model
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
