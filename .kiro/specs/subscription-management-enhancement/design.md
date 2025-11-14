# Design Document

## Overview

This design document outlines the technical approach for enhancing the SpendSense subscription management system. The enhancement adds support for multiple billing cycles, accurate date calculations, notification reminders, and improved user experience for managing recurring payments.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ Subscriptions    │  │  Settings        │                │
│  │ Screen           │  │  Screen          │                │
│  └──────────────────┘  └──────────────────┘                │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     State Management                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              AppState (ChangeNotifier)                │  │
│  │  - Subscription list management                       │  │
│  │  - Billing date calculations                          │  │
│  │  - Notification scheduling coordination               │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Service Layer                             │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ Subscription     │  │  Notification    │                │
│  │ Service          │  │  Service         │                │
│  └──────────────────┘  └──────────────────┘                │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Persistence Layer                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         SharedPreferences / Local Storage             │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Enhanced Subscription Model

**File:** `lib/models/subscription.dart`

```dart
enum BillingCycle {
  weekly,
  monthly,
  quarterly,
  yearly,
}

enum SubscriptionCategory {
  entertainment,
  utilities,
  software,
  health,
  education,
  other,
}

class Subscription {
  final String id;
  final String name;
  final double amount;
  final BillingCycle billingCycle;
  final DateTime startDate;
  final int billingDay; // Day of month for monthly/quarterly/yearly
  DateTime nextBillingDate;
  DateTime? lastPaymentDate;
  bool isFixed;
  SubscriptionCategory category;
  
  // Computed properties
  int get daysRemaining;
  bool get isDueToday;
  bool get isDueTomorrow;
  bool get isOverdue;
  String get statusText;
  Color get statusColor;
  
  // Methods
  void calculateNextBillingDate();
  void markAsPaid();
  Map<String, dynamic> toJson();
  factory Subscription.fromJson(Map<String, dynamic> json);
}
```

**Design Decisions:**
- Use enum for billing cycles to ensure type safety
- Store both `startDate` and `nextBillingDate` for accurate calculations
- Add `lastPaymentDate` for payment history tracking
- Include computed properties for UI convenience
- Implement JSON serialization for persistence

### 2. Subscription Service

**File:** `lib/services/subscription_service.dart`

```dart
class SubscriptionService {
  // Date calculation methods
  DateTime calculateNextBillingDate({
    required DateTime startDate,
    required BillingCycle cycle,
    required int billingDay,
    DateTime? fromDate,
  });
  
  DateTime handleMonthEndEdgeCases({
    required int year,
    required int month,
    required int desiredDay,
  });
  
  // Subscription management
  List<Subscription> getUpcomingSubscriptions(int daysAhead);
  List<Subscription> getOverdueSubscriptions();
  List<Subscription> getSubscriptionsByCategory(SubscriptionCategory category);
  
  // Cost calculations
  double calculateMonthlyCost(List<Subscription> subscriptions);
  double calculateYearlyCost(List<Subscription> subscriptions);
  double calculateQuarterlyCost(List<Subscription> subscriptions);
  Map<BillingCycle, double> getCostBreakdown(List<Subscription> subscriptions);
  
  // Persistence
  Future<void> saveSubscriptions(List<Subscription> subscriptions);
  Future<List<Subscription>> loadSubscriptions();
}
```

**Design Decisions:**
- Centralize date calculation logic for consistency
- Provide filtering and querying methods for UI needs
- Handle edge cases (month-end, leap years) in dedicated methods
- Support cost projections for different time periods

### 3. Notification Service

**File:** `lib/services/notification_service.dart`

```dart
class NotificationService {
  // Initialization
  Future<void> initialize();
  Future<bool> requestPermissions();
  
  // Notification scheduling
  Future<void> scheduleSubscriptionNotifications(Subscription subscription);
  Future<void> cancelSubscriptionNotifications(String subscriptionId);
  Future<void> rescheduleAllNotifications(List<Subscription> subscriptions);
  
  // Notification timing
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  });
  
  // Settings
  Future<void> updateNotificationSettings(NotificationSettings settings);
  Future<NotificationSettings> getNotificationSettings();
}

class NotificationSettings {
  bool enabled;
  bool notify3DaysBefore;
  bool notify1DayBefore;
  bool notifyOnDueDate;
  bool notifyRenewalReminders;
  
  Map<String, dynamic> toJson();
  factory NotificationSettings.fromJson(Map<String, dynamic> json);
}
```

**Design Decisions:**
- Use `flutter_local_notifications` package for cross-platform support
- Generate unique notification IDs based on subscription ID and timing
- Store notification settings separately for flexibility
- Support cancellation and rescheduling for subscription updates

### 4. Enhanced AppState Integration

**File:** `lib/app_state.dart` (modifications)

```dart
class AppState extends ChangeNotifier {
  // Existing code...
  
  // Services
  late final SubscriptionService _subscriptionService;
  late final NotificationService _notificationService;
  
  // Subscription management
  Future<void> addSubscription({
    required String name,
    required double amount,
    required BillingCycle billingCycle,
    required DateTime startDate,
    required int billingDay,
    bool isFixed = true,
    SubscriptionCategory category = SubscriptionCategory.other,
  });
  
  Future<void> updateSubscription(Subscription subscription);
  Future<void> deleteSubscription(String id);
  Future<void> markSubscriptionAsPaid(String id);
  
  // Notification management
  Future<void> updateNotificationSettings(NotificationSettings settings);
  NotificationSettings get notificationSettings;
  
  // Computed properties
  List<Subscription> get upcomingSubscriptions;
  List<Subscription> get overdueSubscriptions;
  Map<SubscriptionCategory, List<Subscription>> get subscriptionsByCategory;
  Map<BillingCycle, double> get costBreakdown;
  double get totalMonthlyCost;
  double get totalYearlyCost;
}
```

**Design Decisions:**
- Integrate services into existing AppState for consistency
- Maintain reactive updates through ChangeNotifier
- Provide computed properties for common UI queries
- Handle notification scheduling automatically on subscription changes

### 5. UI Components

#### Subscriptions Screen Enhancement

**File:** `lib/screens/subscriptions_screen.dart`

**Key Features:**
- Tabbed interface: All / Upcoming / Overdue
- Category filter dropdown
- Subscription cards with visual status indicators
- Cost summary cards (monthly, yearly, quarterly)
- Floating action button for adding subscriptions

**Visual Design:**
```
┌─────────────────────────────────────────┐
│  Subscriptions                    [+]   │
├─────────────────────────────────────────┤
│  [All] [Upcoming] [Overdue]             │
│  Category: [All ▼]                      │
├─────────────────────────────────────────┤
│  ┌───────────────────────────────────┐ │
│  │ 🎬 Netflix                        │ │
│  │ ₹500/month                        │ │
│  │ Due in 5 days • Entertainment     │ │
│  └───────────────────────────────────┘ │
│  ┌───────────────────────────────────┐ │
│  │ 🎵 Spotify                        │ │
│  │ ₹119/month                        │ │
│  │ Due tomorrow • Entertainment      │ │
│  └───────────────────────────────────┘ │
├─────────────────────────────────────────┤
│  Total Monthly: ₹619                    │
│  Total Yearly: ₹7,428                   │
└─────────────────────────────────────────┘
```

#### Add/Edit Subscription Dialog

**Enhanced Fields:**
- Subscription name (text input)
- Amount (number input)
- Billing cycle (dropdown: Weekly, Monthly, Quarterly, Yearly)
- Start date (date picker)
- Billing day (number input, conditional on cycle)
- Category (dropdown)
- Fixed expense toggle

#### Notification Settings Screen

**File:** `lib/screens/notification_settings_screen.dart`

**Features:**
- Master toggle for subscription notifications
- Individual toggles for notification timings
- Test notification button
- Permission status indicator

## Data Models

### Subscription JSON Structure

```json
{
  "id": "uuid-string",
  "name": "Netflix",
  "amount": 500.0,
  "billingCycle": "monthly",
  "startDate": "2024-01-15T00:00:00.000Z",
  "billingDay": 15,
  "nextBillingDate": "2024-12-15T00:00:00.000Z",
  "lastPaymentDate": "2024-11-15T00:00:00.000Z",
  "isFixed": true,
  "category": "entertainment"
}
```

### Notification Settings JSON Structure

```json
{
  "enabled": true,
  "notify3DaysBefore": true,
  "notify1DayBefore": true,
  "notifyOnDueDate": true,
  "notifyRenewalReminders": true
}
```

## Error Handling

### Date Calculation Errors

- **Invalid billing day:** Clamp to valid range (1-31) and use last day of month if needed
- **Leap year handling:** Use DateTime's built-in leap year logic
- **Timezone issues:** Store all dates in UTC, convert to local for display

### Notification Errors

- **Permission denied:** Show settings dialog with explanation
- **Scheduling failure:** Log error, show user-friendly message
- **Background restrictions:** Detect and warn user about battery optimization

### Persistence Errors

- **Save failure:** Retry with exponential backoff, show error toast
- **Load failure:** Fall back to empty list, log error
- **Corruption:** Validate JSON structure, skip invalid entries

## Testing Strategy

### Unit Tests

**File:** `test/services/subscription_service_test.dart`

```dart
group('SubscriptionService', () {
  test('calculates next monthly billing date correctly', () {});
  test('handles month-end edge cases', () {});
  test('calculates yearly billing date correctly', () {});
  test('handles leap year correctly', () {});
  test('calculates days remaining correctly', () {});
  test('identifies overdue subscriptions', () {});
  test('calculates monthly cost correctly', () {});
  test('calculates yearly cost with mixed cycles', () {});
});
```

**File:** `test/services/notification_service_test.dart`

```dart
group('NotificationService', () {
  test('schedules notification at correct time', () {});
  test('generates unique notification IDs', () {});
  test('cancels notifications correctly', () {});
  test('reschedules all notifications', () {});
  test('respects notification settings', () {});
});
```

### Widget Tests

**File:** `test/screens/subscriptions_screen_test.dart`

```dart
group('SubscriptionsScreen', () {
  testWidgets('displays subscriptions list', (tester) async {});
  testWidgets('filters by category', (tester) async {});
  testWidgets('shows correct status colors', (tester) async {});
  testWidgets('opens add dialog on FAB tap', (tester) async {});
  testWidgets('displays cost summaries', (tester) async {});
});
```

### Integration Tests

**File:** `integration_test/subscription_flow_test.dart`

```dart
group('Subscription Flow', () {
  testWidgets('complete subscription lifecycle', (tester) async {
    // Add subscription
    // Verify it appears in list
    // Edit subscription
    // Verify changes
    // Mark as paid
    // Verify next billing date updates
    // Delete subscription
    // Verify removal
  });
  
  testWidgets('notification scheduling', (tester) async {
    // Add subscription
    // Verify notifications scheduled
    // Update subscription
    // Verify notifications rescheduled
    // Delete subscription
    // Verify notifications cancelled
  });
});
```

## Performance Considerations

### Optimization Strategies

1. **Lazy Loading:** Load subscriptions on demand, not at app startup
2. **Caching:** Cache calculated values (days remaining, costs) until data changes
3. **Batch Operations:** Update multiple subscriptions in single transaction
4. **Background Processing:** Calculate next billing dates in isolate for large lists
5. **Notification Batching:** Schedule all notifications in single batch operation

### Memory Management

- Limit subscription list size (warn if > 100 subscriptions)
- Use pagination for very large lists
- Clear cached calculations when memory pressure detected

## Security Considerations

### Data Protection

- Store subscription data in app's private storage
- No sensitive payment information stored (only amounts and dates)
- Validate all user inputs to prevent injection attacks

### Notification Privacy

- Don't include sensitive details in notification preview
- Allow user to disable lock screen notifications
- Clear notifications when app is opened

## Accessibility

### Screen Reader Support

- Provide semantic labels for all interactive elements
- Announce status changes (due today, overdue)
- Support navigation with keyboard/switch control

### Visual Accessibility

- Use color + icon + text for status indicators (not color alone)
- Maintain WCAG AA contrast ratios
- Support dynamic text sizing

## Migration Strategy

### Existing Data Migration

```dart
Future<void> migrateSubscriptions() async {
  final prefs = await SharedPreferences.getInstance();
  final oldData = prefs.getString('subscriptions');
  
  if (oldData != null) {
    final oldSubscriptions = jsonDecode(oldData) as List;
    final newSubscriptions = oldSubscriptions.map((old) {
      return Subscription(
        id: old['id'],
        name: old['name'],
        amount: old['amount'],
        billingCycle: BillingCycle.monthly, // Default for old data
        startDate: DateTime.parse(old['nextBillingDate']).subtract(Duration(days: 30)),
        billingDay: old['billingDay'],
        nextBillingDate: DateTime.parse(old['nextBillingDate']),
        lastPaymentDate: null,
        isFixed: old['isFixed'] ?? true,
        category: SubscriptionCategory.other,
      );
    }).toList();
    
    await _subscriptionService.saveSubscriptions(newSubscriptions);
  }
}
```

## Dependencies

### New Packages

```yaml
dependencies:
  flutter_local_notifications: ^17.0.0  # Local notifications
  timezone: ^0.9.0                      # Timezone handling for notifications
  
dev_dependencies:
  mockito: ^5.4.0                       # Mocking for tests
```

### Platform-Specific Configuration

**Android:** Update `AndroidManifest.xml` for notification permissions
**iOS:** Update `Info.plist` for notification permissions

## Rollout Plan

### Phase 1: Core Functionality (Week 1)
- Enhanced Subscription model
- SubscriptionService with date calculations
- Updated UI for adding/editing subscriptions

### Phase 2: Notifications (Week 2)
- NotificationService implementation
- Notification settings screen
- Notification scheduling integration

### Phase 3: Advanced Features (Week 3)
- Category filtering
- Cost projections
- Payment history tracking

### Phase 4: Polish & Testing (Week 4)
- Comprehensive testing
- Bug fixes
- Performance optimization
- Documentation
