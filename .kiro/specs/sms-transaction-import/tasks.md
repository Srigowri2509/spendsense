# Implementation Plan

- [x] 1. Add required dependencies to pubspec.yaml


  - Add permission_handler package for SMS permission management
  - Add sms_advanced or telephony package for SMS reading
  - Add shared_preferences for storing import history
  - Run flutter pub get to install dependencies
  - _Requirements: 1.1, 2.1_




- [ ] 2. Create ParsedTransaction model
  - Create lib/models/parsed_transaction.dart file
  - Define ParsedTransaction class with amount, merchant, date, paymentMethod, transactionId, type, smsId, smsBody, sender fields
  - Add TransactionType enum (debit, credit)
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 3. Create SmsSenders utility class


  - Create lib/utils/sms_senders.dart file
  - Define lists of known payment app sender addresses (GPAY, PHONEPE, PAYTM, etc.)
  - Define lists of known bank sender addresses (HDFCBK, ICICIB, SBIIN, etc.)
  - Implement getAllSenders() method to return combined list
  - _Requirements: 2.2, 2.6_



- [ ] 4. Create SmsService for reading SMS
  - Create lib/services/sms_service.dart file
  - Implement hasPermission() method to check SMS permission status
  - Implement requestPermission() method to request SMS permission
  - Implement readMessages() method to read SMS from inbox with date range and sender filters
  - Implement filterTransactionSms() method to filter by transaction keywords


  - Handle permission exceptions appropriately
  - _Requirements: 1.1, 1.2, 1.5, 2.1, 2.3, 2.4, 2.5_

- [ ] 5. Create SmsParser for extracting transaction details
  - Create lib/services/sms_parser.dart file
  - Implement parse() method to extract all transaction details from SMS
  - Implement _extractAmount() with regex patterns for various amount formats
  - Implement _extractMerchant() with regex patterns for merchant names and UPI IDs
  - Implement _extractDate() to parse dates from SMS body
  - Implement _extractPaymentMethod() to identify UPI, Card, Bank, Wallet


  - Implement _extractTransactionId() to extract UPI transaction IDs
  - Implement _extractTransactionType() to determine debit or credit
  - Handle currency formats (₹, Rs, INR) and commas in amounts
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9_



- [ ] 6. Create CategoryMatcher for auto-categorization
  - Create lib/utils/category_matcher.dart file
  - Define keyword mappings for each category (food, travel, shopping, luxuries)
  - Implement matchCategory() method to match merchant name to category
  - Return CategoryType.other as default when no match found
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [x] 7. Create TransactionImportService for orchestration


  - Create lib/services/transaction_import_service.dart file
  - Implement scanTransactions() method to scan SMS and return parsed transactions
  - Implement isDuplicate() method to check for existing transactions
  - Implement importTransactions() method to add transactions to backend
  - Implement saveImportHistory() and loadImportHistory() methods using SharedPreferences
  - Track imported SMS IDs to prevent re-import


  - Handle errors and return ImportResult with success/failure counts
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 6.7, 8.3, 8.4, 8.5_

- [ ] 8. Create TransactionPreviewTile widget
  - Create lib/widgets/transaction_preview_tile.dart file
  - Display amount, merchant, date, and suggested category
  - Show checkbox for selection
  - Display category icon
  - Use card layout with proper styling


  - _Requirements: 6.4_

- [ ] 9. Create SmsImportScreen for preview and confirmation
  - Create lib/screens/sms_import_screen.dart file
  - Display header with count of found transactions
  - Show list of TransactionPreviewTile widgets
  - Implement select/deselect all functionality
  - Add bottom bar with "Import Selected" button
  - Show progress indicator during import
  - Display success/error summary dialog after import


  - Handle empty state when no transactions found
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 8.2, 8.6_

- [ ] 10. Create SmsSettingsScreen for configuration
  - Create lib/screens/sms_settings_screen.dart file


  - Add enable/disable SMS import toggle
  - Display SMS permission status indicator
  - Add "Grant Permission" button that opens app settings if permission denied

  - Add date range selector (30/60/90 days dropdown)
  - Display last import timestamp
  - Add "Import Now" button that navigates to SmsImportScreen
  - Add clear import history button
  - Show explanation of SMS usage for privacy
  - _Requirements: 1.3, 1.4, 10.1, 10.2, 10.3, 10.4, 10.6, 10.7, 9.6_


- [ ] 11. Add SMS import entry point in settings screen
  - Update lib/screens/settings_screen.dart
  - Add "SMS Import" list tile in settings
  - Navigate to SmsSettingsScreen when tapped
  - Show icon indicating feature availability
  - _Requirements: 6.1, 10.1_



- [ ] 12. Update AndroidManifest.xml for SMS permissions
  - Add READ_SMS permission to android/app/src/main/AndroidManifest.xml
  - Add RECEIVE_SMS permission for future background sync
  - _Requirements: 1.1, 2.1_

- [ ] 13. Add privacy policy text for SMS usage
  - Create privacy policy explaining SMS data usage
  - Add to SmsSettingsScreen or link to external policy
  - Clearly state that only transaction data is extracted and stored
  - Explain that full SMS content is not stored or transmitted
  - _Requirements: 9.2, 9.3, 9.6, 9.7_

- [ ] 14. Implement error handling and user feedback
  - Add error dialogs for permission denied scenarios
  - Show informative messages when no SMS found
  - Display retry options for backend sync failures
  - Show success snackbar with import count
  - Log parsing errors for debugging
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

- [ ] 15. Add navigation and integrate with existing app
  - Add route for SmsImportScreen in main.dart
  - Add route for SmsSettingsScreen in main.dart
  - Update settings screen to include SMS import option
  - Test navigation flow from settings to import
  - _Requirements: 6.1, 10.1_
