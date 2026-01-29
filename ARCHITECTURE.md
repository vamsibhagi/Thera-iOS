# Thera iOS App Architecture

## Overview
Thera is an iOS application designed to help users manage their screen time through "consumption app" limits. It leverages Apple's `ScreenTime` and `DeviceActivity` frameworks to monitor usage and block applications when limits are reached.

## Core Components

### 1. Thera App (Main Target)
- **`TheraApp.swift`**: Entry point. Requests authorization and sets up the environment.
- **`ScreenTimeManager.swift` (Thera/Managers)**: Singleton responsible for:
    - Managing `FamilyActivitySelection` (Apps & Categories).
    - Requesting Device Activity authorization.
    - Scheduling `DeviceActivityMonitor` tasks (`monitor_UUID` and `monitor_cat_UUID`).
- **`PersistenceManager.swift` (Thera/App)**: Manages all data persistence using `UserDefaults` with an App Group (`group.com.thera.app`) to share data between the main app and extensions.

### 2. Device Activity Monitor Extension (`DeviceActivityMonitor`)
This extension runs in the background and enforces limits.
- **`DeviceActivityMonitorExtension.swift`**:
    - **`intervalDidStart`**: Resets daily limits at midnight.
    - **`eventDidReachThreshold`**: Called when a limit is reached. It moves the App/Category token to the "Shielded" list.
    - **`intervalDidEnd`**: Handles the cleanup of "Probation" (temporary unlock) sessions.
    - **Sync Logic**: `syncShields()` is the critical function that calculates the active shield set by subtracting "Exempt" (Probation) tokens from "Blocked" (Limit Reached) tokens. It uses a **fresh instance of UserDefaults** to avoid race conditions.

### 3. Shield Configuration Extension (`ShieldConfiguration`)
Provides the UI for the "Shield" (Blocking Screen).
- **`ShieldConfigurationExtension.swift`**:
    - Displays a "Stop Scrolling" message.
    - Loads dynamic suggestions from `suggested_tasks.json` to encourage alternative activities.
    - Offers two actions: "I'll do it" (Close App) and "Unlock for 1 min" (Secondary Action).

### 4. Shield Action Extension (`ShieldAction`)
Handles interactions with the Shield buttons.
- **`ShieldActionExtension.swift`**:
    - **Primary Button**: Closes the application.
    - **Secondary Button**: Grants a 1-minute "Probation" unlock.
        - Generates a unique probation ID (`probation_UUID` or `probation_cat_UUID`).
        - Saves a `ProbationToken`.
        - Updates the Shield Store to remove the app/category from the blocked list.
        - Schedules a one-off `DeviceActivity` to re-lock the app after 1 minute.

### 5. Widget Extension (`TheraWidget`)
- Displays current screen time usage on the Home Screen.
- Shares data with the main app via App Group.

## Data Flow
1. **User Sets Limit**: App -> `PersistenceManager` -> `ScreenTimeManager` -> Schedules `DeviceActivity`.
2. **Limit Reached**: `DeviceActivityMonitor` -> Updates `PersistentBlockedTokens` in `UserDefaults` -> Updates `ManagedSettingsStore` (Shields Up).
3. **User Unlocks**: `ShieldAction` -> Add `ProbationToken` -> Updates `ManagedSettingsStore` (Shields Down) -> Schedules One-off Monitor.
4. **Re-lock**: `DeviceActivityMonitor` (One-off) -> Interval Ends -> Removes `ProbationToken` -> Calls `syncShields()` -> Updates `ManagedSettingsStore` (Shields Up).

## Known Issues
- **Concurrent Probation Locking**: Unlocking a second app while one is already unlocked may theoretically cause a re-lock if the sync logic reads stale data, but this has been mitigated with forced `UserDefaults` refresh.

## Key Files
- `Thera/Managers/ScreenTimeManager.swift`
- `DeviceActivityMonitor/DeviceActivityMonitorExtension.swift` ("The Enforcer")
- `ShieldAction/ShieldActionExtension.swift` ("The Unlocker")
- `Thera/App/PersistenceManager.swift`
