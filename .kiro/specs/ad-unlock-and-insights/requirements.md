# Requirements Document

## Introduction

This document outlines the requirements for enhancing the Zensta app locker with three key features: an ad-based temporary unlock system that allows users to unlock locked apps by watching rewarded video ads, improved insights that compare app usage between locked and unlocked days, and cleaner app name display that removes technical package identifiers.

## Glossary

- **Zensta App**: The main application that locks and manages access to other installed apps
- **Locked App**: An application that the user has configured to be blocked for a specified duration
- **Rewarded Video Ad**: A full-screen advertisement that users can watch to earn temporary unlock time
- **Temporary Unlock**: A time-limited period during which a locked app becomes accessible after watching ads
- **Lock Session**: A period during which apps are actively locked by the user
- **Usage Stats**: Historical data about app usage time and patterns
- **App Package Name**: The technical identifier for Android apps (e.g., "com.airbnb.android")
- **Display Name**: The user-friendly name of an app (e.g., "Airbnb")

## Requirements

### Requirement 1

**User Story:** As a user who has locked apps, I want to watch ads to temporarily unlock them, so that I can access important apps during a lock session without completely breaking my focus commitment.

#### Acceptance Criteria

1. WHEN a user attempts to open a locked app, THE Zensta App SHALL display an option to watch a rewarded video ad for temporary unlock
2. WHEN a user successfully watches one rewarded video ad, THE Zensta App SHALL unlock the requested app for 10 minutes
3. WHEN a user watches a second rewarded video ad during the same lock session, THE Zensta App SHALL extend the unlock duration by an additional 10 minutes to total 20 minutes
4. WHEN a user watches additional rewarded video ads, THE Zensta App SHALL increment the unlock duration by 10 minutes per ad watched
5. WHEN the temporary unlock time expires, THE Zensta App SHALL automatically re-lock the app until the original lock duration ends

### Requirement 2

**User Story:** As a user, I want to see the remaining temporary unlock time, so that I know how much time I have left before the app locks again.

#### Acceptance Criteria

1. WHILE an app is temporarily unlocked via ads, THE Zensta App SHALL display a countdown timer showing the remaining unlock time
2. WHEN the temporary unlock time changes, THE Zensta App SHALL update the displayed countdown in real-time
3. WHEN the countdown reaches zero, THE Zensta App SHALL remove the timer display and re-lock the app

### Requirement 3

**User Story:** As a user, I want to view insights comparing my app usage on days when I locked apps versus days when I didn't, so that I can understand the effectiveness of using the app locker.

#### Acceptance Criteria

1. THE Zensta App SHALL track daily app usage statistics for all monitored apps
2. THE Zensta App SHALL categorize each day as either a "locked day" or "unlocked day" based on whether lock sessions were active
3. WHEN a user views the insights page, THE Zensta App SHALL display a comparison of average app usage time between locked days and unlocked days
4. WHEN a user views the insights page, THE Zensta App SHALL display the total number of locked days versus unlocked days
5. WHEN a user views the insights page, THE Zensta App SHALL show usage reduction percentage when comparing locked days to unlocked days

### Requirement 4

**User Story:** As a user searching for apps to lock, I want to see clean app names without technical package identifiers, so that I can easily identify apps by their familiar names.

#### Acceptance Criteria

1. WHEN the Zensta App displays a list of installed apps, THE Zensta App SHALL show only the display name without package identifiers
2. WHEN an app has a display name like "Airbnb", THE Zensta App SHALL display "Airbnb" instead of "android/airbnb" or package names
3. THE Zensta App SHALL extract and display the user-facing app name from the app metadata
4. WHEN searching for apps, THE Zensta App SHALL match search queries against the clean display names

### Requirement 5

**User Story:** As a user, I want the ad-based unlock to persist across app restarts, so that my temporary unlock time doesn't reset if I close and reopen Zensta.

#### Acceptance Criteria

1. WHEN a temporary unlock is active, THE Zensta App SHALL persist the unlock expiration time to local storage
2. WHEN the Zensta App restarts, THE Zensta App SHALL restore any active temporary unlock sessions
3. WHEN the Zensta App restarts and the temporary unlock time has expired, THE Zensta App SHALL not restore the unlock session
