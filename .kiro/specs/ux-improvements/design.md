# Design Document: UX Improvements

## Overview

This design document outlines the implementation approach for six key user experience enhancements to the SpendWise Flutter application. The features focus on improving expense management, data visualization, and user guidance through better UI patterns and interactions.

## Architecture

### Component Structure

```
lib/
├── screens/
│   ├── expense_detail_screen.dart          # NEW: View/edit single expense
│   ├── transactions_screen.dart            # NEW: Filterable transaction list
│   ├── statistics_screen.dart              # NEW: Spending analytics
│   └── [existing screens...]
├── widgets/
│   ├── activity_tile.dart                  # MODIFIED: Add icons, swipe-to-delete
│   ├── empty_state.dart                    # NEW: Reusable empty state widget
│   ├── filter_bottom_sheet.dart            # NEW: Transaction filters
│   ├── icon_picker.dart                    # NEW: Category icon selector
│   └── [existing widgets...]
├── models/
│   └── transaction_filter.dart             # NEW: Filter state model
└── app_state.dart                          # MODIFIED: Add statistics methods
```

## Components and Interfaces

### 1. Expense Editing and Deletion

#### ExpenseDetailScreen
**Purpose**: Display and edit a single transaction

**UI Layout**:
- AppBar with title "Expense Details" and Edit/Delete actions
- Card-based layout showing:
  - Amount (large, prominent)
  - Category (with icon chip)
  - Merchant/Note
  - Date and time
  - Payment source
- Edit mode: Convert to form with same fields as AddExpenseScreen
- Bottom action buttons: Save/Cancel

**State Management**:
```dart
class _ExpenseDetailScreenState {
  bool _isEditing = false;
  late TextEditingController _amountCtrl;
  late TextEditingController _merchantCtrl;
  late CategoryType _selectedCategory;
  
  Future<void> _saveChanges() async {
    // Call app.updateTransaction()
    // Handle success/error
  }
  
  Future<void> _deleteExpense() async {
    // Show confirmation dialog
    // Call app.removeTransaction()
    // Pop with undo option
  }
}
```

#### Swipe-to-Delete in ActivityTile
**Implementation**: Wrap ActivityTile with Dismissible widget

```dart
Dismissible(
  key: Key(item.id),
  direction: DismissDirection.endToStart,
  background: Container(
    alignment: Alignment.centerRight,
    padding: EdgeInsets.only(right: 20),
    color: Colors.red,
    child: Icon(Icons.delete, color: Colors.white),
  ),
  confirmDismiss: (direction) async {
    // Return false to prevent immediate deletion
    // Trigger undo snackbar instead
    return false;
  },
  onDismissed: (direction) {
    // Handle deletion with undo
  },
  child: ActivityTile(item: item),
)
```

### 2. Transaction Filtering and Sorting

#### TransactionFilter Model
```dart
class TransactionFilter {
  final Set<CategoryType>? categories;
  final DateTimeRange? dateRange;
  final double? minAmount;
  final double? maxAmount;
  final String? merchantSearch;
  final TransactionSortType sortBy;
  final bool sortDescending;
  
  List<TransactionItem> apply(List<TransactionItem> transactions) {
    var filtered = transactions;
    
    // Apply category filter
    if (categories != null && categories!.isNotEmpty) {
      filtered = filtered.where((t) => categories!.contains(t.category)).toList();
    }
    
    // Apply date range filter
    if (dateRange != null) {
      filtered = filtered.where((t) => 
        t.time.isAfter(dateRange!.start) && 
        t.time.isBefore(dateRange!.end)
      ).toList();
    }
    
    // Apply amount range filter
    if (minAmount != null) {
      filtered = filtered.where((t) => t.amount >= minAmount!).toList();
    }
    if (maxAmount != null) {
      filtered = filtered.where((t) => t.amount <= maxAmount!).toList();
    }
    
    // Apply merchant search
    if (merchantSearch != null && merchantSearch!.isNotEmpty) {
      filtered = filtered.where((t) => 
        t.merchant.toLowerCase().contains(merchantSearch!.toLowerCase())
      ).toList();
    }
    
    // Apply sorting
    filtered.sort((a, b) {
      int comparison;
      switch (sortBy) {
        case TransactionSortType.date:
          comparison = a.time.compareTo(b.time);
          break;
        case TransactionSortType.amount:
          comparison = a.amount.compareTo(b.amount);
          break;
        case TransactionSortType.merchant:
          comparison = a.merchant.compareTo(b.merchant);
          break;
      }
      return sortDescending ? -comparison : comparison;
    });
    
    return filtered;
  }
}

enum TransactionSortType { date, amount, merchant }
```

#### FilterBottomSheet Widget
**Purpose**: Modal bottom sheet for selecting filters

**UI Components**:
- Category multi-select chips
- Date range picker (preset options: Today, This Week, This Month, Custom)
- Amount range sliders
- Merchant search field
- Sort options (Date/Amount, Ascending/Descending)
- Clear All / Apply buttons

#### TransactionsScreen
**Purpose**: Dedicated screen for viewing all transactions with filters

**UI Layout**:
- AppBar with search field and filter button
- Active filter chips (dismissible)
- Filtered transaction list
- Empty state when no results

### 3. Category Icons

#### Icon Mapping
Add icon property to Category model:

```dart
class Category {
  final CategoryType type;
  final String name;
  final Color color;
  final double monthlyBudget;
  final String? customId;
  final IconData icon; // NEW
  
  const Category(
    this.type, 
    this.name, 
    this.color, 
    this.monthlyBudget, 
    {this.customId, required this.icon}
  );
}
```

**Default Icon Mapping**:
- Food: `Icons.restaurant`
- Travel: `Icons.directions_car`
- Shopping: `Icons.shopping_bag`
- Rent: `Icons.home`
- Luxuries: `Icons.diamond`
- Custom: User-selected from IconPicker

#### IconPicker Widget
**Purpose**: Allow users to select icons for custom categories

**UI**: Grid of common icons organized by category:
- Finance: wallet, credit_card, savings, etc.
- Lifestyle: fitness, health, entertainment, etc.
- Services: wifi, phone, utilities, etc.
- Other: miscellaneous icons

#### UI Updates
- **ActivityTile**: Show category icon in leading CircleAvatar
- **AddExpenseScreen**: Show icons in category chips
- **SpendingScreen**: Show icons in category tiles
- **Charts**: Include icons in legends

### 4. Expense Statistics

#### Statistics Methods in AppState
```dart
class AppState {
  // Average daily spending for current month
  double get averageDailySpending {
    final now = DateTime.now();
    final monthTransactions = transactions.where((t) => 
      t.time.year == now.year && t.time.month == now.month
    ).toList();
    
    if (monthTransactions.isEmpty) return 0;
    
    final total = monthTransactions.fold(0.0, (sum, t) => sum + t.amount);
    return total / now.day;
  }
  
  // Highest expense this month
  TransactionItem? get highestExpense {
    final now = DateTime.now();
    final monthTransactions = transactions.where((t) => 
      t.time.year == now.year && t.time.month == now.month
    ).toList();
    
    if (monthTransactions.isEmpty) return null;
    
    return monthTransactions.reduce((a, b) => a.amount > b.amount ? a : b);
  }
  
  // Lowest expense this month
  TransactionItem? get lowestExpense {
    final now = DateTime.now();
    final monthTransactions = transactions.where((t) => 
      t.time.year == now.year && t.time.month == now.month
    ).toList();
    
    if (monthTransactions.isEmpty) return null;
    
    return monthTransactions.reduce((a, b) => a.amount < b.amount ? a : b);
  }
  
  // Most frequent merchant
  String? get mostFrequentMerchant {
    final now = DateTime.now();
    final monthTransactions = transactions.where((t) => 
      t.time.year == now.year && t.time.month == now.month
    ).toList();
    
    if (monthTransactions.isEmpty) return null;
    
    final merchantCounts = <String, int>{};
    for (final t in monthTransactions) {
      merchantCounts[t.merchant] = (merchantCounts[t.merchant] ?? 0) + 1;
    }
    
    return merchantCounts.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;
  }
  
  // Spending by day of week
  Map<String, double> get spendingByDayOfWeek {
    final now = DateTime.now();
    final monthTransactions = transactions.where((t) => 
      t.time.year == now.year && t.time.month == now.month
    ).toList();
    
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final spending = <String, double>{};
    
    for (final day in dayNames) {
      spending[day] = 0;
    }
    
    for (final t in monthTransactions) {
      final dayIndex = t.time.weekday - 1; // Monday = 0
      spending[dayNames[dayIndex]] = 
        (spending[dayNames[dayIndex]] ?? 0) + t.amount;
    }
    
    return spending;
  }
}
```

#### StatisticsScreen
**Purpose**: Display spending analytics and insights

**UI Layout**:
- Header: "Statistics for [Month Year]"
- Cards for each statistic:
  1. **Average Daily Spending**
     - Large number display
     - Comparison to budget (on track indicator)
  
  2. **Highest/Lowest Expenses**
     - Side-by-side cards
     - Show merchant, amount, date
     - Tap to view details
  
  3. **Most Frequent Merchant**
     - Merchant name
     - Number of transactions
     - Total spent
  
  4. **Spending by Day of Week**
     - Bar chart showing spending per day
     - Identify patterns (e.g., "You spend more on weekends")

- Empty state when insufficient data

### 5. Undo Delete Functionality

#### Implementation Strategy
Use a delayed deletion pattern with ScaffoldMessenger:

```dart
class _DeletionManager {
  TransactionItem? _pendingDeletion;
  Timer? _deletionTimer;
  
  void scheduleDelete(
    BuildContext context,
    TransactionItem item,
    AppState app,
  ) {
    // Cancel any pending deletion
    _deletionTimer?.cancel();
    _pendingDeletion = item;
    
    // Remove from UI immediately
    app.transactions.remove(item);
    app.notifyListeners();
    
    // Show snackbar with undo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${item.merchant}'),
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            _cancelDeletion(app);
          },
        ),
      ),
    ).closed.then((reason) {
      // If snackbar closed without undo, commit deletion
      if (reason != SnackBarClosedReason.action) {
        _commitDeletion(app);
      }
    });
  }
  
  void _cancelDeletion(AppState app) {
    if (_pendingDeletion != null) {
      app.transactions.add(_pendingDeletion!);
      app.notifyListeners();
      _pendingDeletion = null;
    }
  }
  
  Future<void> _commitDeletion(AppState app) async {
    if (_pendingDeletion != null) {
      try {
        await app.removeTransaction(_pendingDeletion!.id);
      } catch (e) {
        // If backend fails, restore the item
        app.transactions.add(_pendingDeletion!);
        app.notifyListeners();
      }
      _pendingDeletion = null;
    }
  }
}
```

**User Flow**:
1. User swipes to delete or taps delete button
2. Item disappears from list immediately
3. Snackbar appears: "Deleted [Merchant]" with UNDO button
4. If user taps UNDO within 5 seconds:
   - Item reappears in list
   - No backend call made
5. If timeout expires:
   - Backend deletion API called
   - Item permanently removed

### 6. Empty State Improvements

#### EmptyState Widget
**Purpose**: Reusable component for empty states

```dart
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

#### Empty State Scenarios

1. **No Transactions**
   - Icon: `Icons.receipt_long_outlined`
   - Title: "No expenses yet"
   - Message: "Start tracking your spending by adding your first expense"
   - Action: "Add Expense" → Navigate to AddExpenseScreen

2. **No Filter Results**
   - Icon: `Icons.search_off`
   - Title: "No matching expenses"
   - Message: "Try adjusting your filters to see more results"
   - Action: "Clear Filters"

3. **No Statistics Data**
   - Icon: `Icons.analytics_outlined`
   - Title: "Not enough data"
   - Message: "Add more expenses to see detailed statistics and insights"
   - Action: "Add Expense"

4. **No Subscriptions**
   - Icon: `Icons.subscriptions_outlined`
   - Title: "No subscriptions"
   - Message: "Track your recurring payments by adding subscriptions"
   - Action: "Add Subscription"

5. **No Categories Selected**
   - Icon: `Icons.category_outlined`
   - Title: "No categories selected"
   - Message: "Select at least one category to view expenses"
   - Action: "Select Categories"

## Data Models

### TransactionFilter
```dart
class TransactionFilter {
  final Set<CategoryType>? categories;
  final DateTimeRange? dateRange;
  final double? minAmount;
  final double? maxAmount;
  final String? merchantSearch;
  final TransactionSortType sortBy;
  final bool sortDescending;
  
  TransactionFilter({
    this.categories,
    this.dateRange,
    this.minAmount,
    this.maxAmount,
    this.merchantSearch,
    this.sortBy = TransactionSortType.date,
    this.sortDescending = true,
  });
  
  bool get hasActiveFilters =>
      (categories != null && categories!.isNotEmpty) ||
      dateRange != null ||
      minAmount != null ||
      maxAmount != null ||
      (merchantSearch != null && merchantSearch!.isNotEmpty);
  
  TransactionFilter copyWith({...}) { /* implementation */ }
  
  List<TransactionItem> apply(List<TransactionItem> transactions) { /* implementation */ }
}
```

### Category (Modified)
```dart
class Category {
  final CategoryType type;
  final String name;
  final Color color;
  final double monthlyBudget;
  final String? customId;
  final IconData icon; // NEW
  
  const Category(
    this.type,
    this.name,
    this.color,
    this.monthlyBudget,
    {this.customId, required this.icon}
  );
  
  Category copyWith({
    double? monthlyBudget,
    IconData? icon,
  }) {
    return Category(
      type,
      name,
      color,
      monthlyBudget ?? this.monthlyBudget,
      customId: customId,
      icon: icon ?? this.icon,
    );
  }
}
```

## Error Handling

### Backend API Failures
- **Edit Expense**: Show error snackbar, retain original data
- **Delete Expense**: If backend fails after undo timeout, restore item and show error
- **Network Errors**: Display user-friendly message with retry option

### Validation
- **Amount**: Must be positive number
- **Merchant**: Cannot be empty
- **Date**: Cannot be in future
- **Category**: Must be selected

### Edge Cases
- **Concurrent Edits**: Last write wins (no conflict resolution needed for single-user app)
- **Deleted Item Edit**: Check if item exists before allowing edit
- **Empty Filter Results**: Show appropriate empty state
- **No Data for Statistics**: Show empty state with guidance

## Testing Strategy

### Unit Tests
- TransactionFilter.apply() with various filter combinations
- Statistics calculations (averages, min/max, grouping)
- Category icon mapping
- Empty state condition logic

### Widget Tests
- EmptyState widget rendering
- FilterBottomSheet interactions
- ExpenseDetailScreen edit mode
- Dismissible swipe gesture
- IconPicker selection

### Integration Tests
- Complete edit flow: tap → edit → save → verify
- Complete delete flow: swipe → undo → verify restoration
- Filter application: select filters → verify results
- Statistics screen: verify calculations match displayed values

### Manual Testing Scenarios
1. Edit expense with network failure
2. Delete expense and undo before timeout
3. Delete expense and let timeout expire
4. Apply multiple filters simultaneously
5. Navigate away during pending deletion
6. Create custom category with icon
7. View statistics with various data amounts
8. Test all empty states

## Performance Considerations

### Filtering Performance
- Filter operations run on UI thread
- For large transaction lists (>1000), consider:
  - Debouncing search input
  - Pagination of results
  - Background isolate for filtering

### State Management
- Use `notifyListeners()` sparingly
- Batch updates when applying multiple changes
- Consider selective rebuilds with Consumer widgets

### Memory Management
- Dispose controllers in StatefulWidgets
- Cancel timers in deletion manager
- Clear filter state when not needed

## Accessibility

- All interactive elements have semantic labels
- Color is not the only indicator (use icons + text)
- Sufficient contrast ratios for text
- Touch targets minimum 48x48 dp
- Screen reader support for all actions
- Keyboard navigation support (web/desktop)

## Future Enhancements

- Export filtered transactions to CSV
- Save filter presets
- Advanced statistics (trends, predictions)
- Bulk edit/delete operations
- Transaction categories auto-suggestion based on merchant
- Receipt attachment to transactions
