# Implementation Plan

- [x] 1. Create data models for ad unlock and usage tracking

  - [x] 1.1 Create AdUnlockState model with JSON serialization


    - Implement model with adsWatched, unlockExpiresAt, and lockSessionId fields
    - Add totalUnlockDuration getter that calculates 10 minutes per ad
    - Add isActive getter to check if unlock is still valid
    - Implement toJson() and fromJson() methods for persistence
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 5.1, 5.2_


  
  - [ ] 1.2 Create DailyUsageRecord model with JSON serialization
    - Implement model with date, appUsageTimes map, hadActiveLocks, and lockSessionCount fields
    - Add totalUsage getter to sum all app usage durations


    - Implement toJson() and fromJson() methods for persistence
    - _Requirements: 3.1, 3.2_

  


  - [ ] 1.3 Create InsightsData and AppUsageComparison models
    - Implement InsightsData with locked/unlocked day counts, average usage durations, and reduction percent
    - Implement AppUsageComparison for per-app breakdown
    - _Requirements: 3.3, 3.4, 3.5_



- [ ] 2. Implement AdUnlockController for managing ad-based unlocks
  - [ ] 2.1 Create AdUnlockController as StateNotifier
    - Set up state as Map<String, AdUnlockState> keyed by package name
    - Implement state persistence using SharedPreferences
    - Add method to generate unique lock session IDs
    - Implement state restoration on controller initialization
    - _Requirements: 1.1, 5.1, 5.2, 5.3_
  
  - [x] 2.2 Implement watchAdToUnlock method


    - Check if ad is ready using AdService.isRewardedAdReady
    - Show rewarded ad using AdService.showRewardedAd()
    - Increment adsWatched count if ad was successfully watched
    - Calculate new unlock duration (10 minutes × adsWatched)
    - Update AppRule via RulesController.setTempUnlock()


    - Update AdUnlockState with new expiration time
    - Persist updated state to SharedPreferences

    - Return true if successful, false otherwise


    - _Requirements: 1.1, 1.2, 1.3, 1.4_
  
  - [ ] 2.3 Implement helper methods for ad unlock management
    - Add getAdsWatchedForPackage() to retrieve current ad count
    - Add getTotalUnlockDuration() to calculate cumulative unlock time
    - Add resetAdCountForPackage() to clear state when lock expires


    - Add method to clean up expired unlock states
    - _Requirements: 1.1, 1.2, 1.3, 1.4_
  
  - [ ] 2.4 Create Riverpod provider for AdUnlockController
    - Define adUnlockProvider as StateNotifierProvider


    - Ensure provider is accessible throughout the app
    - _Requirements: 1.1_


- [x] 3. Implement UsageTrackingService for insights data collection


  - [ ] 3.1 Create UsageTrackingService class
    - Set up SharedPreferences for data persistence
    - Implement method to query Android usage stats using usage_stats package
    - Add method to record daily usage for monitored apps


    - Implement method to check if a day had active lock sessions
    - Add method to save DailyUsageRecord to SharedPreferences
    - _Requirements: 3.1, 3.2_
  
  - [x] 3.2 Implement data retrieval and aggregation methods


    - Add method to load usage history from SharedPreferences
    - Implement filtering by date range
    - Add method to separate locked days from unlocked days
    - Implement data cleanup for records older than 90 days


    - _Requirements: 3.1, 3.2_
  

  - [x] 3.3 Add background tracking initialization


    - Initialize tracking when app starts
    - Record daily usage at end of day or app close
    - Handle permission denied gracefully
    - _Requirements: 3.1_

- [ ] 4. Implement InsightsController for comparison calculations
  - [x] 4.1 Create InsightsController class


    - Set up dependency on UsageTrackingService
    - Implement getComparison() method with date range parameter
    - Calculate locked days count and unlocked days count
    - _Requirements: 3.2, 3.4_
  


  - [ ] 4.2 Implement usage comparison calculations
    - Calculate average usage on locked days
    - Calculate average usage on unlocked days

    - Compute usage reduction percentage: ((unlocked - locked) / unlocked) × 100


    - Handle edge cases (no data, division by zero)
    - _Requirements: 3.3, 3.5_
  
  - [ ] 4.3 Implement per-app comparison breakdown
    - For each app, calculate average usage on locked vs unlocked days


    - Compute per-app change percentage
    - Return Map of AppUsageComparison objects
    - _Requirements: 3.5_
  
  - [x] 4.4 Create Riverpod provider for InsightsController


    - Define insightsProvider as FutureProvider
    - Add family modifier for date range parameter

    - _Requirements: 3.3_



- [ ] 5. Create UI components for ad unlock feature
  - [ ] 5.1 Create AdUnlockButton widget
    - Display "Watch Ad to Unlock" button on locked app cards
    - Show ads watched count and remaining unlock time


    - Enable button only when rule.canWatchAdToUnlock is true
    - Handle button press to trigger AdUnlockController.watchAdToUnlock()
    - Show loading indicator while ad is loading
    - Display error message if ad fails to load
    - _Requirements: 1.1, 1.2_


  
  - [ ] 5.2 Create UnlockTimerWidget for countdown display
    - Display real-time countdown of remaining unlock time
    - Update every second using Timer
    - Format as "Unlocked for MM:SS"


    - Dispose timer when widget is disposed
    - _Requirements: 2.1, 2.2, 2.3_
  
  - [x] 5.3 Integrate ad unlock UI into HomePage

    - Add AdUnlockButton to locked app cards
    - Show UnlockTimerWidget when app is temporarily unlocked
    - Update UI when unlock expires
    - _Requirements: 1.1, 2.1_

- [x] 6. Implement clean app name display


  - [ ] 6.1 Create AppNameFormatter utility class
    - Implement getCleanName() static method

    - Remove package-like prefixes (android/, com., etc.)

    - Handle edge cases (empty names, special characters)
    - Capitalize first letter if needed
    - _Requirements: 4.1, 4.2, 4.3_
  
  - [ ] 6.2 Update AppPickerPage to use clean names
    - Replace subtitle (package name) with clean name only in title
    - Remove package name from UI display

    - Update search to match only against clean display names
    - Keep package name in memory for internal use
    - _Requirements: 4.1, 4.2, 4.4_
  
  - [ ] 6.3 Update other UI components showing app names
    - Update HomePage locked app cards to show clean names

    - Update any other places displaying app names
    - _Requirements: 4.1, 4.2_

- [ ] 7. Create InsightsPage UI
  - [ ] 7.1 Create InsightsPage scaffold and layout
    - Set up Scaffold with AppBar

    - Create scrollable column layout
    - Add time range selector (7 days, 30 days, all time)
    - Implement pull-to-refresh functionality
    - _Requirements: 3.3_
  

  - [x] 7.2 Create summary cards for locked vs unlocked days

    - Display locked days count in a card
    - Display unlocked days count in a card
    - Use AppColors theme for styling
    - Add icons for visual appeal
    - _Requirements: 3.4_

  
  - [ ] 7.3 Create usage comparison visualization
    - Display average usage on locked days
    - Display average usage on unlocked days
    - Show usage reduction percentage with color coding (green for reduction)
    - Add animated progress bars for visual comparison

    - _Requirements: 3.3, 3.5_
  
  - [ ] 7.4 Create per-app breakdown section
    - List each monitored app with before/after comparison


    - Show app icon, name, and usage change

    - Display percentage change with color coding
    - _Requirements: 3.5_
  
  - [ ] 7.5 Handle empty and error states
    - Show message when no data available

    - Display permission prompt if usage stats not granted
    - Add button to open app settings for permission
    - Show loading indicator while data is being fetched
    - _Requirements: 3.1_
  

  - [ ] 7.6 Add navigation to InsightsPage
    - Add insights tab or button in root navigation
    - Ensure page is accessible from main app flow
    - _Requirements: 3.3_

- [ ] 8. Implement error handling and edge cases
  - [x] 8.1 Handle ad loading failures

    - Catch exceptions from AdService
    - Display user-friendly error message
    - Provide retry button
    - Don't increment ad count on failure
    - Preload next ad in background

    - _Requirements: 1.1_
  
  - [ ] 8.2 Handle usage stats permission denied
    - Check permission status before querying usage stats
    - Show limited insights if permission denied
    - Display message prompting user to grant permission
    - Provide button to open settings
    - _Requirements: 3.1_
  
  - [ ] 8.3 Handle data persistence failures
    - Wrap SharedPreferences writes in try-catch
    - Keep data in memory if write fails
    - Retry on next state change
    - Log errors for debugging
    - _Requirements: 5.1, 5.2_
  
  - [ ] 8.4 Handle corrupted data recovery
    - Catch JSON parsing errors when loading state
    - Reset to default state if data is corrupted
    - Log error for debugging
    - Optionally notify user of data reset
    - _Requirements: 5.2, 5.3_

- [ ] 9. Add performance optimizations
  - [ ] 9.1 Implement ad preloading
    - Preload rewarded ad on app initialization
    - Load next ad immediately after one is shown
    - Cache ad availability status
    - _Requirements: 1.1_
  
  - [ ] 9.2 Optimize usage stats queries
    - Query usage stats once per day, cache results
    - Use background isolate for heavy calculations
    - Limit historical data to 90 days
    - Implement data aggregation for old records
    - _Requirements: 3.1_
  
  - [ ] 9.3 Optimize UI responsiveness
    - Use FutureBuilder for async data loading in InsightsPage
    - Implement debounced search in AppPickerPage (300ms)
    - Show loading indicators during data fetch
    - _Requirements: 3.3, 4.4_

- [ ] 10. Integration and final touches
  - [ ] 10.1 Ensure ad unlock persists across app restarts
    - Verify AdUnlockState is saved to SharedPreferences
    - Test state restoration on app restart
    - Verify expired unlocks are not restored
    - _Requirements: 5.1, 5.2, 5.3_
  
  - [ ] 10.2 Verify unlock timer accuracy
    - Test countdown updates every second
    - Verify timer stops when unlock expires
    - Test timer behavior when app is backgrounded
    - _Requirements: 2.1, 2.2, 2.3_
  
  - [ ] 10.3 Test complete ad unlock flow
    - Lock an app for 3 hours
    - Wait for 50% progress
    - Watch first ad, verify 10-minute unlock
    - Watch second ad, verify 20-minute cumulative unlock
    - Verify unlock expires and app re-locks
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_
  
  - [ ] 10.4 Test insights comparison accuracy
    - Create test data with locked and unlocked days
    - Verify comparison calculations are correct
    - Test edge cases (all locked, all unlocked, no data)
    - _Requirements: 3.2, 3.3, 3.4, 3.5_
  
  - [ ] 10.5 Verify clean app names throughout app
    - Check AppPickerPage shows clean names
    - Verify HomePage shows clean names
    - Test search functionality with clean names
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
