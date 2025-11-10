# Design Document

## Overview

This design document outlines the implementation approach for three interconnected features in the Zensta app:

1. **Ad-based Temporary Unlock System**: Allows users to watch rewarded video ads to temporarily unlock apps during active lock sessions, with incremental unlock time (10 minutes per ad)
2. **Enhanced Insights with Lock Comparison**: Provides analytics comparing app usage on days when locks were active versus days without locks
3. **Clean App Name Display**: Removes technical package identifiers from app listings, showing only user-friendly display names

The design leverages the existing architecture including Riverpod state management, the AdService for rewarded ads, and the RulesController for lock management.

## Architecture

### High-Level Component Interaction

```
┌─────────────────┐
│   UI Layer      │
│  - HomePage     │
│  - InsightsPage │
│  - AppPicker    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────────┐
│  Controllers    │◄────►│   Services       │
│  - Rules        │      │  - AdService     │
│  - AdUnlock     │      │  - UsageStats    │
└────────┬────────┘      └──────────────────┘
         │
         ▼
┌─────────────────┐
│   Models        │
│  - AppRule      │
│  - AdUnlock     │
│  - UsageData    │
└─────────────────┘
```

## Components and Interfaces

### 1. Ad-Based Unlock System

#### 1.1 AdUnlockController

A new Riverpod StateNotifier that manages ad-based temporary unlocks.

**Responsibilities:**
- Track the number of ads watched per lock session
- Calculate cumulative unlock duration (10 min × ads watched)
- Coordinate with AdService to show rewarded ads
- Update AppRule with temporary unlock time
- Persist ad unlock state across app restarts

**Key Methods:**
```dart
class AdUnlockController extends StateNotifier<Map<String, AdUnlockState>> {
  Future<bool> watchAdToUnlock(String packageName);
  int getAdsWatchedForPackage(String packageName);
  Duration getTotalUnlockDuration(String packageName);
  void resetAdCountForPackage(String packageName);
}
```

**State Structure:**
```dart
class AdUnlockState {
  final int adsWatched;
  final DateTime? unlockExpiresAt;
  final String lockSessionId; // Unique ID per lock session
}
```

#### 1.2 Integration with Existing AppRule

The existing `AppRule` model already has `tempUnlockUntil` field and the `active` getter checks this field. We'll leverage this existing infrastructure:

- When an ad is watched, calculate new unlock time: `DateTime.now().add(Duration(minutes: 10 * adsWatched))`
- Update the rule using `RulesController.setTempUnlock()`
- The existing `_syncAndroidKeysForPackage()` will handle native side synchronization

#### 1.3 UI Components

**AdUnlockButton Widget:**
- Displays "Watch Ad to Unlock" button on locked app cards
- Shows ads watched count and remaining unlock time
- Only enabled when `rule.canWatchAdToUnlock` returns true (50% progress)
- Handles ad loading states and errors

**UnlockTimerWidget:**
- Real-time countdown display for temporary unlock
- Updates every second
- Shows format: "Unlocked for 8:45"

### 2. Enhanced Insights System

#### 2.1 UsageTrackingService

A new service that tracks daily app usage and lock session data.

**Responsibilities:**
- Record daily usage statistics for monitored apps
- Track which days had active lock sessions
- Categorize days as "locked" or "unlocked"
- Persist historical data locally using SharedPreferences

**Data Structure:**
```dart
class DailyUsageRecord {
  final DateTime date;
  final Map<String, Duration> appUsageTimes; // packageName -> duration
  final bool hadActiveLocks;
  final int lockSessionCount;
}
```

**Storage Format:**
```json
{
  "usage_history": [
    {
      "date": "2025-11-08",
      "apps": {
        "com.airbnb.android": 3600,
        "com.instagram.android": 7200
      },
      "hadLocks": true,
      "sessions": 2
    }
  ]
}
```

#### 2.2 InsightsController

A Riverpod provider that computes comparison metrics.

**Key Methods:**
```dart
class InsightsController {
  Future<InsightsData> getComparison({int days = 30});
  Map<String, Duration> getAverageUsageByDay(bool lockedDays);
  double getUsageReductionPercent();
}
```

**Computed Metrics:**
```dart
class InsightsData {
  final int lockedDaysCount;
  final int unlockedDaysCount;
  final Duration avgUsageOnLockedDays;
  final Duration avgUsageOnUnlockedDays;
  final double reductionPercent;
  final Map<String, AppUsageComparison> perAppComparison;
}
```

#### 2.3 InsightsPage UI

**Layout Structure:**
- Summary cards showing locked vs unlocked days count
- Bar chart comparing average usage times
- Percentage reduction metric with visual indicator
- Per-app breakdown with before/after comparison
- Time range selector (7 days, 30 days, all time)

**Visual Design:**
- Use existing AppColors theme
- Animated progress bars for comparisons
- Color coding: green for reduction, red for increase

### 3. Clean App Name Display

#### 3.1 App Name Formatting Utility

A utility function to extract clean display names from app metadata.

**Implementation:**
```dart
class AppNameFormatter {
  static String getCleanName(AppInfo app) {
    // Use the app.name field which already contains the display name
    // Remove any package-like prefixes if they exist
    String name = app.name;
    
    // Remove patterns like "android/", "com.", etc.
    if (name.contains('/')) {
      name = name.split('/').last;
    }
    
    // Capitalize first letter if needed
    if (name.isNotEmpty) {
      name = name[0].toUpperCase() + name.substring(1);
    }
    
    return name;
  }
}
```

#### 3.2 AppPickerPage Updates

**Changes:**
- Remove subtitle showing `app.packageName`
- Display only the clean name in the title
- Update search to match only against display name
- Keep package name in memory for internal use but hide from UI

**Updated ListTile:**
```dart
ListTile(
  leading: CircleAvatar(...),
  title: Text(AppNameFormatter.getCleanName(app)),
  // No subtitle with package name
  onTap: () => Navigator.pop(context, app),
)
```

## Data Models

### AdUnlockState Model

```dart
class AdUnlockState {
  final int adsWatched;
  final DateTime? unlockExpiresAt;
  final String lockSessionId;
  
  AdUnlockState({
    required this.adsWatched,
    this.unlockExpiresAt,
    required this.lockSessionId,
  });
  
  Duration get totalUnlockDuration => Duration(minutes: 10 * adsWatched);
  
  bool get isActive => 
    unlockExpiresAt != null && unlockExpiresAt!.isAfter(DateTime.now());
  
  Map<String, dynamic> toJson();
  factory AdUnlockState.fromJson(Map<String, dynamic> json);
}
```

### DailyUsageRecord Model

```dart
class DailyUsageRecord {
  final DateTime date;
  final Map<String, Duration> appUsageTimes;
  final bool hadActiveLocks;
  final int lockSessionCount;
  
  DailyUsageRecord({
    required this.date,
    required this.appUsageTimes,
    required this.hadActiveLocks,
    required this.lockSessionCount,
  });
  
  Duration get totalUsage => appUsageTimes.values.fold(
    Duration.zero, 
    (sum, duration) => sum + duration
  );
  
  Map<String, dynamic> toJson();
  factory DailyUsageRecord.fromJson(Map<String, dynamic> json);
}
```

### InsightsData Model

```dart
class InsightsData {
  final int lockedDaysCount;
  final int unlockedDaysCount;
  final Duration avgUsageOnLockedDays;
  final Duration avgUsageOnUnlockedDays;
  final double reductionPercent;
  final Map<String, AppUsageComparison> perAppComparison;
  
  InsightsData({
    required this.lockedDaysCount,
    required this.unlockedDaysCount,
    required this.avgUsageOnLockedDays,
    required this.avgUsageOnUnlockedDays,
    required this.reductionPercent,
    required this.perAppComparison,
  });
}

class AppUsageComparison {
  final String appName;
  final Duration avgWhenLocked;
  final Duration avgWhenUnlocked;
  final double changePercent;
  
  AppUsageComparison({
    required this.appName,
    required this.avgWhenLocked,
    required this.avgWhenUnlocked,
    required this.changePercent,
  });
}
```

## Error Handling

### Ad Loading Failures

**Scenario:** Rewarded ad fails to load or show
**Handling:**
- Display user-friendly error message: "Ad not available right now"
- Provide retry button
- Log error for debugging
- Don't increment ads watched count
- Preload next ad in background

**Implementation:**
```dart
try {
  final earned = await AdService().showRewardedAd();
  if (earned) {
    // Grant unlock
  } else {
    // Show error
  }
} catch (e) {
  showSnackBar('Unable to load ad. Please try again.');
}
```

### Usage Stats Permission Denied

**Scenario:** User denies PACKAGE_USAGE_STATS permission
**Handling:**
- Show insights page with limited data
- Display message: "Grant usage access for detailed insights"
- Provide button to open settings
- Fall back to manual tracking based on lock sessions only

### Data Persistence Failures

**Scenario:** SharedPreferences write fails
**Handling:**
- Keep data in memory for current session
- Retry write on next state change
- Log error for debugging
- Don't crash the app

### Invalid State Recovery

**Scenario:** Corrupted data in SharedPreferences
**Handling:**
- Catch JSON parsing errors
- Reset to default state
- Log error
- Notify user: "Usage history reset due to data error"

## Testing Strategy

### Unit Tests

**AdUnlockController Tests:**
- Test ad count increments correctly
- Verify unlock duration calculation (10 min × count)
- Test session ID generation and reset
- Verify state persistence and restoration

**UsageTrackingService Tests:**
- Test daily record creation
- Verify usage aggregation logic
- Test locked/unlocked day categorization
- Verify data serialization/deserialization

**InsightsController Tests:**
- Test comparison metric calculations
- Verify percentage reduction formula
- Test edge cases (no data, all locked, all unlocked)
- Test date range filtering

**AppNameFormatter Tests:**
- Test various package name formats
- Verify clean name extraction
- Test edge cases (empty, special characters)

### Integration Tests

**Ad Unlock Flow:**
1. Create active lock rule
2. Wait for 50% progress
3. Watch ad
4. Verify temporary unlock applied
5. Verify timer countdown
6. Watch second ad
7. Verify cumulative unlock time

**Insights Data Flow:**
1. Create lock sessions
2. Simulate usage data
3. Verify daily records created
4. Check comparison calculations
5. Verify UI displays correct metrics

### Widget Tests

**AdUnlockButton:**
- Test button enabled/disabled states
- Verify ad count display
- Test loading states
- Verify error handling UI

**InsightsPage:**
- Test data display with mock data
- Verify chart rendering
- Test empty state
- Test time range selector

**AppPickerPage:**
- Verify clean names displayed
- Test search functionality
- Verify package names hidden
- Test app selection

### Manual Testing Checklist

- [ ] Watch ad and verify 10-minute unlock
- [ ] Watch multiple ads and verify cumulative time
- [ ] Verify unlock persists across app restart
- [ ] Check insights show correct locked vs unlocked days
- [ ] Verify usage reduction percentage accurate
- [ ] Confirm app names display without package identifiers
- [ ] Test with no usage stats permission
- [ ] Test ad loading failures
- [ ] Verify timer countdown accuracy
- [ ] Test with scheduled and quick locks

## Performance Considerations

### Ad Loading
- Preload rewarded ads in background after initialization
- Load next ad immediately after one is shown
- Cache ad availability status to avoid UI flicker

### Usage Stats Queries
- Query usage stats once per day, not on every app open
- Cache results in memory for current session
- Use background isolate for heavy calculations
- Limit historical data to 90 days to keep storage manageable

### UI Responsiveness
- Use FutureBuilder for async data loading
- Show loading indicators during data fetch
- Implement pull-to-refresh for insights page
- Debounce search input in app picker (300ms)

### Storage Optimization
- Compress usage history using efficient JSON structure
- Aggregate old data (>30 days) into weekly summaries
- Implement data cleanup for records older than 90 days
- Use batch writes to SharedPreferences

## Security and Privacy

### Usage Data
- Store all usage data locally only (no cloud sync)
- Don't collect data for system apps
- Allow user to clear usage history
- Don't track apps outside of lock management

### Ad Integration
- Use test ad units during development
- Implement ad frequency capping (max 10 ads per hour)
- Don't force ads on users
- Respect user's ad preferences

### Permissions
- Request PACKAGE_USAGE_STATS only when needed
- Explain permission purpose clearly
- Gracefully degrade if permission denied
- Don't repeatedly prompt for denied permissions

## Migration and Compatibility

### Existing Data
- Existing AppRule objects already support `tempUnlockUntil`
- No migration needed for lock rules
- Initialize ad unlock state as empty map
- Create usage history starting from update date

### Backward Compatibility
- New features are additive, don't break existing functionality
- App picker changes are UI-only, no data model changes
- Insights page is new, no existing code to migrate

### Version Handling
- Store schema version in SharedPreferences
- Implement data migration logic for future updates
- Handle missing fields gracefully with defaults
