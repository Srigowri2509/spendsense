# Requirements Document

## Introduction

This specification defines enhancements to the SpendSense subscription management system to support multiple billing cycles (monthly, yearly, quarterly), accurate next billing date calculations, improved day counting logic, and proactive notification reminders for upcoming subscription payments.

## Glossary

- **System**: The SpendSense mobile application
- **User**: A person using the SpendSense app to track expenses and subscriptions
- **Subscription**: A recurring payment obligation (e.g., Netflix, Spotify)
- **Billing Cycle**: The frequency at which a subscription renews (monthly, yearly, quarterly, weekly)
- **Next Billing Date**: The calculated date when the next subscription payment is due
- **Notification Service**: The system component responsible for scheduling and displaying local notifications
- **Days Remaining**: The number of days between the current date and the next billing date

## Requirements

### Requirement 1: Support Multiple Billing Cycles

**User Story:** As a user, I want to specify different billing cycles for my subscriptions (monthly, yearly, quarterly, weekly), so that I can accurately track all my recurring payments regardless of their frequency.

#### Acceptance Criteria

1. WHEN the User adds a new subscription, THE System SHALL provide options to select billing cycle from: Monthly, Yearly, Quarterly, Weekly
2. WHEN the User selects a billing cycle, THE System SHALL store the billing cycle type with the subscription data
3. WHEN the User views a subscription, THE System SHALL display the billing cycle type clearly
4. WHERE a subscription has a yearly billing cycle, THE System SHALL calculate the next billing date as 12 months from the start date
5. WHERE a subscription has a quarterly billing cycle, THE System SHALL calculate the next billing date as 3 months from the start date
6. WHERE a subscription has a weekly billing cycle, THE System SHALL calculate the next billing date as 7 days from the start date

### Requirement 2: Accurate Next Billing Date Calculation

**User Story:** As a user, I want the app to automatically calculate the correct next billing date based on my subscription's billing cycle and start date, so that I always know when my next payment is due without manual calculation.

#### Acceptance Criteria

1. WHEN the User adds a subscription with a start date, THE System SHALL calculate the next billing date based on the billing cycle
2. WHEN the current date passes the next billing date, THE System SHALL automatically recalculate the next billing date for the following cycle
3. WHILE calculating monthly billing dates, THE System SHALL handle month-end edge cases (e.g., billing day 31 in February becomes February 28/29)
4. WHEN a subscription has a billing day that exceeds the days in a month, THE System SHALL use the last day of that month
5. THE System SHALL persist the calculated next billing date with the subscription data
6. WHEN the User opens the subscriptions screen, THE System SHALL display accurate days remaining for each subscription

### Requirement 3: Improved Days Remaining Logic

**User Story:** As a user, I want to see accurate countdown of days remaining until my next subscription payment, so that I can plan my budget accordingly.

#### Acceptance Criteria

1. THE System SHALL calculate days remaining as the difference between the next billing date and the current date
2. WHEN a subscription is due today, THE System SHALL display "Due today!" with visual emphasis
3. WHEN a subscription is due tomorrow, THE System SHALL display "Due tomorrow" with visual emphasis
4. WHEN a subscription is due within 3 days, THE System SHALL display the countdown in red color
5. WHEN a subscription is due within 7 days, THE System SHALL display the countdown in orange color
6. WHEN a subscription is overdue, THE System SHALL display "Overdue by X days" in red with high visual emphasis
7. THE System SHALL update days remaining calculations when the app is opened or resumed

### Requirement 4: Subscription Payment Notifications

**User Story:** As a user, I want to receive notifications before my subscription payments are due, so that I can ensure I have sufficient funds and avoid payment failures.

#### Acceptance Criteria

1. WHEN the User enables subscription notifications in settings, THE System SHALL schedule local notifications for upcoming subscription payments
2. THE System SHALL send a notification 3 days before a subscription payment is due
3. THE System SHALL send a notification 1 day before a subscription payment is due
4. THE System SHALL send a notification on the day a subscription payment is due
5. WHEN a notification is displayed, THE System SHALL include the subscription name and amount
6. WHEN the User taps a notification, THE System SHALL navigate to the subscriptions screen
7. THE System SHALL reschedule notifications when a subscription is added, modified, or deleted
8. WHERE notifications are disabled by the User, THE System SHALL not send subscription payment reminders

### Requirement 5: Notification Settings Management

**User Story:** As a user, I want to control when and how I receive subscription notifications, so that I can customize alerts to my preferences.

#### Acceptance Criteria

1. THE System SHALL provide a settings toggle to enable or disable subscription notifications
2. THE System SHALL provide options to customize notification timing (3 days, 1 day, same day)
3. WHEN the User changes notification settings, THE System SHALL immediately apply the new preferences
4. THE System SHALL persist notification preferences across app sessions
5. WHEN the User disables all notification timings, THE System SHALL stop scheduling subscription notifications
6. THE System SHALL display the current notification settings status in the settings screen

### Requirement 6: Subscription Editing and Management

**User Story:** As a user, I want to edit my existing subscriptions to update billing information, so that I can keep my subscription data accurate when plans change.

#### Acceptance Criteria

1. WHEN the User taps on a subscription, THE System SHALL display an edit dialog with current subscription details
2. THE System SHALL allow the User to modify subscription name, amount, billing cycle, and billing day
3. WHEN the User updates a subscription, THE System SHALL recalculate the next billing date based on new values
4. THE System SHALL allow the User to delete a subscription
5. WHEN a subscription is deleted, THE System SHALL cancel any scheduled notifications for that subscription
6. THE System SHALL provide visual confirmation when a subscription is updated or deleted

### Requirement 7: Total Cost Projections

**User Story:** As a user, I want to see projected subscription costs for different time periods, so that I can understand my long-term subscription commitments.

#### Acceptance Criteria

1. THE System SHALL calculate and display total monthly subscription cost
2. THE System SHALL calculate and display total yearly subscription cost (including yearly subscriptions)
3. THE System SHALL calculate and display total quarterly subscription cost
4. WHEN viewing subscription totals, THE System SHALL break down costs by billing cycle type
5. THE System SHALL update cost projections immediately when subscriptions are added, modified, or deleted

### Requirement 8: Subscription History and Tracking

**User Story:** As a user, I want to track when my subscriptions were last paid, so that I can verify payments and identify any billing issues.

#### Acceptance Criteria

1. THE System SHALL store the last payment date for each subscription
2. WHEN a subscription's next billing date passes, THE System SHALL update the last payment date to the previous billing date
3. THE System SHALL display the last payment date in the subscription details
4. THE System SHALL allow the User to manually mark a subscription as paid
5. WHEN a subscription is marked as paid, THE System SHALL update the next billing date to the following cycle

### Requirement 9: Subscription Categories and Filtering

**User Story:** As a user, I want to categorize my subscriptions (Entertainment, Utilities, Software, etc.), so that I can organize and filter my recurring payments.

#### Acceptance Criteria

1. THE System SHALL provide predefined subscription categories: Entertainment, Utilities, Software, Health, Education, Other
2. WHEN adding a subscription, THE System SHALL allow the User to select a category
3. THE System SHALL allow the User to filter subscriptions by category
4. THE System SHALL display category-wise subscription totals
5. THE System SHALL allow the User to create custom subscription categories

### Requirement 10: Subscription Renewal Reminders

**User Story:** As a user, I want to be reminded about subscription renewals well in advance, so that I can decide whether to continue or cancel before being charged.

#### Acceptance Criteria

1. WHEN a yearly subscription is due within 30 days, THE System SHALL send a renewal reminder notification
2. WHEN a monthly subscription is due within 7 days, THE System SHALL send a renewal reminder notification
3. THE System SHALL include subscription details and renewal date in reminder notifications
4. THE System SHALL provide a "Review Subscription" action in the notification
5. WHEN the User taps "Review Subscription", THE System SHALL navigate to the subscription edit screen
