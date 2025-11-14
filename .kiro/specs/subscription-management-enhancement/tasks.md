# Implementation Plan

- [x] 1. Create enhanced Subscription model with billing cycles


  - Create `lib/models/subscription.dart` with BillingCycle enum (weekly, monthly, quarterly, yearly)
  - Add SubscriptionCategory enum (entertainment, utilities, software, health, education, other)
  - Implement Subscription class with all required fields (id, name, amount, billingCycle, startDate, billingDay, nextBillingDate, lastPaymentDate, isFixed, category)
  - Add computed properties: daysRemaining, isDueToday, isDueTomorrow, isOverdue, statusText, statusColor
  - Implement toJson() and fromJson() methods for persistence
  - _Requirements: 1.1, 1.2, 1.3, 9.1, 9.2_





- [ ] 2. Implement SubscriptionService for date calculations
  - [ ] 2.1 Create `lib/services/subscription_service.dart` file
    - Implement calculateNextBillingDate() method with support for all billing cycles
    - Handle monthly billing with month-end edge cases (billing day 31 in February)

    - Implement handleMonthEndEdgeCases() for proper date clamping
    - Add support for weekly, quarterly, and yearly billing cycles
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 1.4, 1.5, 1.6_
  
  - [x] 2.2 Add subscription query and filtering methods

    - Implement getUpcomingSubscriptions(int daysAhead) method
    - Implement getOverdueSubscriptions() method
    - Implement getSubscriptionsByCategory(SubscriptionCategory category) method
    - _Requirements: 3.6, 9.3_
  
  - [x] 2.3 Implement cost calculation methods

    - Add calculateMonthlyCost() for monthly cost projection
    - Add calculateYearlyCost() for yearly cost projection
    - Add calculateQuarterlyCost() for quarterly cost projection
    - Implement getCostBreakdown() to group costs by billing cycle




    - _Requirements: 7.1, 7.2, 7.3, 7.4_
  
  - [ ] 2.4 Add persistence methods
    - Implement saveSubscriptions() using SharedPreferences
    - Implement loadSubscriptions() with JSON deserialization

    - Add error handling for save/load failures
    - _Requirements: 2.5_

- [ ] 3. Create NotificationService for subscription reminders
  - [ ] 3.1 Set up notification infrastructure
    - Add flutter_local_notifications and timezone packages to pubspec.yaml
    - Create `lib/services/notification_service.dart` file

    - Implement initialize() method with platform-specific setup
    - Implement requestPermissions() method
    - _Requirements: 4.1_
  
  - [x] 3.2 Implement notification scheduling logic

    - Create scheduleSubscriptionNotifications() method for a single subscription
    - Schedule 3-day advance notification
    - Schedule 1-day advance notification
    - Schedule same-day notification

    - Generate unique notification IDs based on subscription ID and timing
    - _Requirements: 4.2, 4.3, 4.4_
  
  - [ ] 3.3 Add notification content and actions
    - Format notification title and body with subscription name and amount



    - Add payload for navigation to subscriptions screen
    - Implement notification tap handler
    - _Requirements: 4.5, 4.6_
  
  - [x] 3.4 Implement notification management methods

    - Add cancelSubscriptionNotifications() for removing scheduled notifications
    - Add rescheduleAllNotifications() for bulk rescheduling
    - _Requirements: 4.7_
  
  - [ ] 3.5 Create NotificationSettings model and persistence
    - Define NotificationSettings class with all toggle options
    - Implement toJson() and fromJson() methods
    - Add updateNotificationSettings() method

    - Add getNotificationSettings() method with SharedPreferences
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 4.8_

- [ ] 4. Update AppState with subscription management
  - [ ] 4.1 Integrate services into AppState
    - Add SubscriptionService instance to AppState
    - Add NotificationService instance to AppState
    - Initialize services in AppState.initialize()

    - _Requirements: 2.1_
  
  - [ ] 4.2 Implement subscription CRUD operations
    - Update addSubscription() method with new parameters (billingCycle, startDate, category)
    - Calculate nextBillingDate using SubscriptionService




    - Schedule notifications after adding subscription
    - Add updateSubscription() method with recalculation logic
    - Add deleteSubscription() method with notification cancellation
    - Add markSubscriptionAsPaid() method to update payment history
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 8.4, 8.5_
  
  - [ ] 4.3 Add computed properties for UI
    - Implement upcomingSubscriptions getter
    - Implement overdueSubscriptions getter
    - Implement subscriptionsByCategory getter
    - Implement costBreakdown getter
    - Implement totalMonthlyCost getter
    - Implement totalYearlyCost getter
    - _Requirements: 7.1, 7.2, 7.4, 9.4_
  
  - [ ] 4.4 Add notification settings management
    - Add notificationSettings property to AppState
    - Implement updateNotificationSettings() method
    - Reschedule all notifications when settings change
    - Persist settings changes
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ] 5. Enhance subscriptions screen UI
  - [ ] 5.1 Update subscriptions_screen.dart layout
    - Add tabbed interface with All, Upcoming, Overdue tabs
    - Add category filter dropdown
    - Update subscription card design with visual status indicators
    - Add color coding: red for due within 3 days, orange for due within 7 days
    - Display "Due today!", "Due tomorrow", or "X days remaining" text
    - Show "Overdue by X days" for overdue subscriptions
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 9.3_
  
  - [ ] 5.2 Add cost summary section
    - Create cost summary cards showing monthly, yearly, quarterly totals
    - Display breakdown by billing cycle type
    - Update totals reactively when subscriptions change
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_
  
  - [ ] 5.3 Implement subscription card tap handler
    - Open edit dialog when subscription card is tapped
    - Pre-fill dialog with current subscription data
    - _Requirements: 6.1_

- [ ] 6. Create enhanced add/edit subscription dialog
  - [ ] 6.1 Update dialog UI with new fields
    - Add billing cycle dropdown (Weekly, Monthly, Quarterly, Yearly)
    - Add start date picker
    - Add category dropdown with predefined categories
    - Keep existing fields: name, amount, billing day, fixed toggle
    - _Requirements: 1.1, 9.1, 9.2_
  
  - [ ] 6.2 Implement form validation
    - Validate subscription name is not empty
    - Validate amount is positive number
    - Validate billing day is between 1-31
    - Validate start date is not in future (or allow with warning)
    - _Requirements: 6.2_
  
  - [ ] 6.3 Add save and delete actions
    - Call AppState.addSubscription() or updateSubscription() on save
    - Show confirmation dialog before deletion
    - Call AppState.deleteSubscription() on delete
    - Display success/error messages
    - _Requirements: 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ] 7. Create notification settings screen
  - [ ] 7.1 Create `lib/screens/notification_settings_screen.dart`
    - Add master toggle for subscription notifications
    - Add toggle for 3-day advance notifications
    - Add toggle for 1-day advance notifications
    - Add toggle for same-day notifications
    - Add toggle for renewal reminders
    - _Requirements: 5.1, 5.2_
  
  - [ ] 7.2 Add permission status indicator
    - Display current notification permission status
    - Add button to open app settings if permission denied
    - Show explanation of why permission is needed
    - _Requirements: 4.1_
  
  - [ ] 7.3 Implement settings persistence
    - Save settings changes immediately to SharedPreferences
    - Load settings on screen init
    - Update AppState when settings change
    - _Requirements: 5.3, 5.4_
  
  - [ ] 7.4 Add test notification button
    - Create button to send test notification
    - Use sample subscription data for test
    - Verify notification appears correctly
    - _Requirements: 5.6_

- [ ] 8. Implement subscription history tracking
  - [ ] 8.1 Add last payment date display
    - Show last payment date in subscription details
    - Format date in user-friendly format
    - _Requirements: 8.1, 8.3_
  
  - [ ] 8.2 Implement automatic payment date updates
    - Update lastPaymentDate when nextBillingDate passes
    - Recalculate nextBillingDate for next cycle
    - Run check on app startup and resume
    - _Requirements: 8.2_
  
  - [ ] 8.3 Add manual "Mark as Paid" action
    - Add button in subscription details to mark as paid
    - Update lastPaymentDate to current date
    - Recalculate nextBillingDate for next cycle
    - Reschedule notifications
    - _Requirements: 8.4, 8.5_

- [ ] 9. Add subscription categories and custom categories
  - [ ] 9.1 Implement category filtering
    - Add category filter dropdown to subscriptions screen
    - Filter subscription list by selected category
    - Show "All" option to clear filter
    - _Requirements: 9.3_
  
  - [ ] 9.2 Display category-wise totals
    - Calculate total cost per category
    - Display in expandable section or separate screen
    - _Requirements: 9.4_
  
  - [ ] 9.3 Add custom category creation
    - Add "Add Custom Category" option in category dropdown
    - Show dialog to enter custom category name
    - Store custom categories in SharedPreferences
    - _Requirements: 9.5_

- [ ] 10. Implement renewal reminder notifications
  - [ ] 10.1 Add renewal reminder scheduling
    - Schedule 30-day advance reminder for yearly subscriptions
    - Schedule 7-day advance reminder for monthly subscriptions
    - Include "Review Subscription" action in notification
    - _Requirements: 10.1, 10.2, 10.3_
  
  - [ ] 10.2 Implement review subscription action
    - Handle notification tap with "Review Subscription" action
    - Navigate to subscription edit screen
    - Pre-select the subscription that triggered notification
    - _Requirements: 10.4, 10.5_

- [ ] 11. Add data migration for existing subscriptions
  - [ ] 11.1 Create migration utility
    - Create `lib/utils/subscription_migration.dart` file
    - Implement migrateSubscriptions() method
    - Read old subscription data format
    - Convert to new format with default values
    - Save migrated data
    - _Requirements: 2.1, 2.2_
  
  - [ ] 11.2 Run migration on app startup
    - Check for old data format in AppState.initialize()
    - Run migration if old data exists
    - Mark migration as complete to avoid re-running
    - _Requirements: 2.1_

- [ ] 12. Update platform-specific configurations
  - [ ] 12.1 Update Android configuration
    - Add notification permissions to AndroidManifest.xml
    - Add notification channel configuration
    - Test notification display on Android
    - _Requirements: 4.1_
  
  - [ ] 12.2 Update iOS configuration
    - Add notification permissions to Info.plist
    - Configure notification categories
    - Test notification display on iOS
    - _Requirements: 4.1_

- [ ] 13. Add error handling and edge cases
  - [ ] 13.1 Handle date calculation edge cases
    - Test and fix month-end edge cases (e.g., Jan 31 → Feb 28/29)
    - Handle leap year correctly
    - Test timezone edge cases
    - _Requirements: 2.3, 2.4_
  
  - [ ] 13.2 Handle notification errors
    - Show user-friendly message if permission denied
    - Handle scheduling failures gracefully
    - Detect and warn about battery optimization restrictions
    - _Requirements: 4.1, 4.7_
  
  - [ ] 13.3 Handle persistence errors
    - Implement retry logic for save failures
    - Fall back to empty list on load failure
    - Validate JSON structure and skip invalid entries
    - _Requirements: 2.5_

- [ ] 14. Implement accessibility features
  - [ ] 14.1 Add semantic labels
    - Add semantic labels to all interactive elements
    - Provide meaningful descriptions for screen readers
    - Support keyboard/switch control navigation
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_
  
  - [ ] 14.2 Ensure visual accessibility
    - Use color + icon + text for status (not color alone)
    - Verify WCAG AA contrast ratios
    - Test with dynamic text sizing
    - _Requirements: 3.4, 3.5_

- [ ] 15. Performance optimization
  - [ ] 15.1 Implement caching
    - Cache calculated values (days remaining, costs)
    - Invalidate cache when subscription data changes
    - _Requirements: 3.7_
  
  - [ ] 15.2 Optimize notification scheduling
    - Batch schedule all notifications in single operation
    - Avoid rescheduling unchanged subscriptions
    - _Requirements: 4.7_

- [ ]* 16. Write comprehensive tests
  - [ ]* 16.1 Write unit tests for SubscriptionService
    - Test calculateNextBillingDate() for all billing cycles
    - Test month-end edge cases
    - Test leap year handling
    - Test cost calculation methods
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 7.1, 7.2, 7.3_
  
  - [ ]* 16.2 Write unit tests for NotificationService
    - Test notification scheduling
    - Test notification ID generation
    - Test cancellation and rescheduling
    - Test settings persistence
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.7_
  
  - [ ]* 16.3 Write widget tests for UI components
    - Test subscriptions screen rendering
    - Test category filtering
    - Test status color display
    - Test add/edit dialog
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 9.3_
  
  - [ ]* 16.4 Write integration tests
    - Test complete subscription lifecycle (add, edit, delete)
    - Test notification scheduling integration
    - Test data persistence
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 4.7_

- [ ] 17. Update home screen with subscription reminders
  - Update upcoming bills section to use new subscription model
  - Display subscriptions with accurate days remaining
  - Show visual indicators for urgent subscriptions
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [ ] 18. Add settings integration
  - Add "Subscription Notifications" option in settings screen
  - Link to notification settings screen
  - Show notification status summary
  - _Requirements: 5.1, 5.6_

- [ ] 19. Documentation and polish
  - Add inline code documentation
  - Update README with new features
  - Create user guide for subscription management
  - Add tooltips for complex UI elements
  - _Requirements: All_
