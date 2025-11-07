# Implementation Plan

- [x] 1. Add category icons to the Category model and update existing categories


  - Update the Category class in app_state.dart to include an IconData field
  - Add icon parameter to Category constructor (required named parameter)
  - Update all existing category definitions with appropriate icons (food: restaurant, travel: directions_car, shopping: shopping_bag, rent: home, luxuries: diamond)
  - Update Category.copyWith() method to include icon parameter
  - Update addCustomCategory() method to accept icon parameter
  - _Requirements: 3.1, 3.2_

- [x] 2. Create reusable EmptyState widget


  - Create lib/widgets/empty_state.dart file
  - Implement EmptyState widget with icon, title, message, and optional action button
  - Use theme-aware styling for colors and typography
  - Support optional action callback and label
  - _Requirements: 6.1, 6.2, 6.6, 6.7_

- [x] 3. Update ActivityTile widget to display category icons


  - Modify lib/widgets/activity_tile.dart to get icon from category
  - Update the icon getter to use app.categories to find matching category and return its icon
  - Display category icon in the leading CircleAvatar
  - _Requirements: 3.2, 3.4_

- [x] 4. Update AddExpenseScreen to show category icons in chips


  - Modify lib/screens/add_expense_screen.dart category chips
  - Add avatar parameter to ChoiceChip widgets with category icon
  - Update custom category dialog to include icon picker
  - _Requirements: 3.2, 3.5_

- [x] 5. Create IconPicker widget for custom category icon selection


  - Create lib/widgets/icon_picker.dart file
  - Implement grid of common icons organized by groups (finance, lifestyle, services, other)
  - Support icon selection with visual feedback
  - Return selected IconData when user taps an icon
  - _Requirements: 3.3_

- [x] 6. Add statistics calculation methods to AppState



  - Add averageDailySpending getter to calculate average spending per day for current month
  - Add highestExpense getter to find transaction with maximum amount this month
  - Add lowestExpense getter to find transaction with minimum amount this month
  - Add mostFrequentMerchant getter to identify merchant with most transactions this month
  - Add spendingByDayOfWeek getter to group spending by weekday
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 7. Create StatisticsScreen to display spending analytics


  - Create lib/screens/statistics_screen.dart file
  - Display header with current month and year
  - Create card for average daily spending with on-track indicator
  - Create side-by-side cards for highest and lowest expenses
  - Create card for most frequent merchant with transaction count
  - Create bar chart card for spending by day of week
  - Show EmptyState when no transactions exist
  - _Requirements: 4.6, 4.7_

- [x] 8. Create ExpenseDetailScreen for viewing and editing expenses


  - Create lib/screens/expense_detail_screen.dart file
  - Display transaction details in card layout (amount, category, merchant, date, source)
  - Add edit button in AppBar to toggle edit mode
  - Implement edit mode with text controllers for amount and merchant
  - Add category selector in edit mode
  - Implement save functionality calling app.updateTransaction()
  - Handle backend errors with user-friendly messages
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.7_

- [x] 9. Implement delete functionality with confirmation in ExpenseDetailScreen


  - Add delete button in AppBar
  - Show confirmation dialog before deletion
  - Call app.removeTransaction() on confirmation
  - Navigate back after successful deletion
  - Handle backend errors gracefully
  - _Requirements: 1.6, 1.7_

- [x] 10. Add swipe-to-delete with undo functionality


  - Create deletion manager helper class to handle pending deletions
  - Wrap ActivityTile with Dismissible widget in relevant screens
  - Implement red delete background with icon
  - On swipe, remove item from UI and show snackbar with UNDO button
  - Implement 5-second timer for permanent deletion
  - Restore item if UNDO is tapped before timeout
  - Call backend removeTransaction() only after timeout expires
  - Handle backend failures by restoring item
  - _Requirements: 1.5, 1.6, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [x] 11. Create TransactionFilter model for filtering logic


  - Create lib/models/transaction_filter.dart file
  - Define TransactionFilter class with category, date range, amount range, merchant search, and sort options
  - Implement apply() method to filter and sort transaction list
  - Add hasActiveFilters getter to check if any filters are active
  - Implement copyWith() method for immutable updates
  - Define TransactionSortType enum (date, amount, merchant)
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] 12. Create FilterBottomSheet widget for filter selection


  - Create lib/widgets/filter_bottom_sheet.dart file
  - Implement category multi-select with chips
  - Add date range picker with preset options (Today, This Week, This Month, Custom)
  - Add amount range input fields
  - Add merchant search text field
  - Add sort options (Date/Amount, Ascending/Descending)
  - Add Clear All and Apply buttons
  - Return TransactionFilter when Apply is tapped
  - _Requirements: 2.1, 2.7_

- [x] 13. Create TransactionsScreen with filtering and sorting


  - Create lib/screens/transactions_screen.dart file
  - Add AppBar with search field and filter button
  - Display active filter chips that can be dismissed
  - Show filtered transaction list using TransactionFilter.apply()
  - Make transactions tappable to navigate to ExpenseDetailScreen
  - Show EmptyState when no transactions match filters
  - Show EmptyState when no transactions exist at all
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 6.1, 6.3_

- [x] 14. Add empty states to existing screens


  - Update home_screen.dart to show EmptyState when no transactions exist
  - Update spending_screen.dart to show EmptyState for categories with no expenses
  - Update subscriptions_screen.dart to show EmptyState when no subscriptions exist
  - Ensure all empty states have appropriate icons, messages, and actions
  - _Requirements: 6.1, 6.2, 6.4, 6.5, 6.7_

- [x] 15. Add navigation to new screens from existing UI



  - Add navigation to StatisticsScreen from insights or home screen
  - Add navigation to TransactionsScreen from home screen or spending screen
  - Update ActivityTile tap handler to navigate to ExpenseDetailScreen
  - Update spending screen transaction items to navigate to ExpenseDetailScreen
  - _Requirements: 1.1, 2.1, 4.6_
