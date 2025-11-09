# Requirements Document

## Introduction

This document outlines the requirements for implementing automatic transaction import from SMS messages in the SpendWise application. The feature will read UPI transaction SMS from popular payment apps and banks, parse transaction details, and automatically add them to the user's expense tracking.

## Glossary

- **SpendWise_App**: The Flutter-based expense tracking mobile application
- **UPI**: Unified Payments Interface - India's instant payment system
- **SMS_Parser**: Component that extracts transaction data from SMS text
- **Transaction_SMS**: SMS message containing payment/transaction information
- **Auto_Import**: Automatic addition of transactions without manual user entry
- **SMS_Permission**: Android runtime permission to read SMS messages
- **Payment_App**: UPI apps like Google Pay, PhonePe, Paytm, etc.
- **Bank_SMS**: Transaction alert messages sent by banks

## Requirements

### Requirement 1: SMS Permission Management

**User Story:** As a user, I want to grant SMS permission to the app, so that it can automatically import my transactions.

#### Acceptance Criteria

1. WHEN a user first accesses the SMS import feature, THE SpendWise_App SHALL request READ_SMS permission
2. WHEN the user grants SMS permission, THE SpendWise_App SHALL proceed to scan SMS messages
3. WHEN the user denies SMS permission, THE SpendWise_App SHALL display an explanation of why the permission is needed
4. WHEN the user denies SMS permission, THE SpendWise_App SHALL provide a button to open app settings
5. THE SpendWise_App SHALL check if SMS permission is granted before attempting to read messages
6. WHEN SMS permission is revoked, THE SpendWise_App SHALL disable auto-import and notify the user
7. THE SpendWise_App SHALL store the permission status to avoid repeated requests

### Requirement 2: SMS Reading and Filtering

**User Story:** As a user, I want the app to read only transaction-related SMS, so that my privacy is protected.

#### Acceptance Criteria

1. THE SpendWise_App SHALL read SMS messages from the device inbox
2. THE SpendWise_App SHALL filter SMS messages by sender addresses of known payment apps and banks
3. WHEN reading SMS messages, THE SpendWise_App SHALL only process messages from the last 90 days
4. THE SpendWise_App SHALL identify transaction SMS by keywords (debited, credited, paid, sent, received, UPI)
5. THE SpendWise_App SHALL ignore non-transaction SMS messages
6. THE SpendWise_App SHALL support SMS from Google Pay, PhonePe, Paytm, and major Indian banks
7. THE SpendWise_App SHALL not store or transmit SMS content except parsed transaction data

### Requirement 3: Transaction Parsing

**User Story:** As a user, I want the app to accurately extract transaction details from SMS, so that my expenses are recorded correctly.

#### Acceptance Criteria

1. THE SpendWise_App SHALL extract the transaction amount from SMS text
2. THE SpendWise_App SHALL extract the merchant or recipient name from SMS text
3. THE SpendWise_App SHALL extract the transaction date and time from SMS text
4. THE SpendWise_App SHALL extract the payment method (UPI, card, bank transfer) from SMS text
5. THE SpendWise_App SHALL extract the UPI transaction ID when available
6. WHEN amount cannot be parsed, THE SpendWise_App SHALL skip that SMS message
7. WHEN merchant name is not found, THE SpendWise_App SHALL use "Unknown" as default
8. THE SpendWise_App SHALL handle multiple currency formats (₹, Rs, INR)
9. THE SpendWise_App SHALL parse amounts with commas and decimal points correctly

### Requirement 4: Duplicate Detection

**User Story:** As a user, I want the app to avoid importing duplicate transactions, so that my expense records are accurate.

#### Acceptance Criteria

1. THE SpendWise_App SHALL check if a transaction already exists before importing
2. WHEN checking for duplicates, THE SpendWise_App SHALL compare amount, date, and merchant
3. WHEN a duplicate is detected, THE SpendWise_App SHALL skip importing that transaction
4. THE SpendWise_App SHALL consider transactions within 1 minute of each other as potential duplicates
5. WHEN a transaction matches an existing manual entry, THE SpendWise_App SHALL not create a duplicate
6. THE SpendWise_App SHALL maintain a list of imported SMS message IDs to prevent re-processing
7. WHEN the same SMS is read multiple times, THE SpendWise_App SHALL not import it again

### Requirement 5: Automatic Categorization

**User Story:** As a user, I want imported transactions to be automatically categorized, so that I don't have to manually categorize each one.

#### Acceptance Criteria

1. THE SpendWise_App SHALL attempt to categorize transactions based on merchant name
2. WHEN merchant name contains food-related keywords, THE SpendWise_App SHALL categorize as Food
3. WHEN merchant name contains travel-related keywords, THE SpendWise_App SHALL categorize as Travel
4. WHEN merchant name contains shopping-related keywords, THE SpendWise_App SHALL categorize as Shopping
5. WHEN merchant name matches known subscription services, THE SpendWise_App SHALL categorize as Luxuries
6. WHEN category cannot be determined, THE SpendWise_App SHALL use "Other" as default
7. THE SpendWise_App SHALL allow users to manually recategorize imported transactions

### Requirement 6: Import Process and Sync

**User Story:** As a user, I want to control when transactions are imported, so that I can review them before they appear in my records.

#### Acceptance Criteria

1. THE SpendWise_App SHALL provide a manual "Import from SMS" button in settings
2. WHEN the user triggers import, THE SpendWise_App SHALL scan SMS and display found transactions
3. THE SpendWise_App SHALL show a preview list of transactions to be imported
4. WHEN displaying preview, THE SpendWise_App SHALL show amount, merchant, date, and suggested category
5. THE SpendWise_App SHALL allow users to select/deselect transactions before importing
6. WHEN the user confirms import, THE SpendWise_App SHALL add selected transactions to the backend
7. THE SpendWise_App SHALL display import progress with count of successful and failed imports
8. WHEN import is complete, THE SpendWise_App SHALL show a summary (X transactions imported)

### Requirement 7: Background Sync (Optional)

**User Story:** As a user, I want transactions to be imported automatically in the background, so that my records are always up to date.

#### Acceptance Criteria

1. THE SpendWise_App SHALL provide an option to enable automatic background import
2. WHEN background import is enabled, THE SpendWise_App SHALL check for new transaction SMS periodically
3. THE SpendWise_App SHALL run background import at most once per hour
4. WHEN new transactions are found, THE SpendWise_App SHALL import them automatically
5. WHEN background import adds transactions, THE SpendWise_App SHALL show a notification
6. THE SpendWise_App SHALL respect battery optimization settings
7. WHEN the user disables background import, THE SpendWise_App SHALL stop automatic scanning

### Requirement 8: Error Handling and User Feedback

**User Story:** As a user, I want to be informed of any issues during import, so that I can take corrective action.

#### Acceptance Criteria

1. WHEN SMS permission is denied, THE SpendWise_App SHALL display a clear error message
2. WHEN no transaction SMS are found, THE SpendWise_App SHALL inform the user
3. WHEN parsing fails for an SMS, THE SpendWise_App SHALL log the error and continue with other messages
4. WHEN backend sync fails, THE SpendWise_App SHALL retry up to 3 times
5. IF backend sync fails after retries, THEN THE SpendWise_App SHALL save transactions locally and retry later
6. WHEN import is successful, THE SpendWise_App SHALL show a success message with count
7. THE SpendWise_App SHALL provide a way to view import history and errors

### Requirement 9: Privacy and Security

**User Story:** As a user, I want my SMS data to be handled securely, so that my privacy is protected.

#### Acceptance Criteria

1. THE SpendWise_App SHALL only read SMS messages, never send or modify them
2. THE SpendWise_App SHALL not store full SMS content on device or server
3. THE SpendWise_App SHALL only extract and store transaction-related data
4. THE SpendWise_App SHALL process SMS locally on the device
5. THE SpendWise_App SHALL only send parsed transaction data to the backend
6. THE SpendWise_App SHALL provide a privacy policy explaining SMS usage
7. THE SpendWise_App SHALL allow users to disable SMS import at any time

### Requirement 10: Settings and Configuration

**User Story:** As a user, I want to configure SMS import settings, so that it works according to my preferences.

#### Acceptance Criteria

1. THE SpendWise_App SHALL provide SMS import settings in the settings screen
2. THE SpendWise_App SHALL allow users to enable/disable SMS import
3. THE SpendWise_App SHALL allow users to enable/disable background sync
4. THE SpendWise_App SHALL allow users to set the date range for SMS scanning (30/60/90 days)
5. THE SpendWise_App SHALL allow users to add custom SMS sender addresses
6. THE SpendWise_App SHALL display the last import date and time
7. THE SpendWise_App SHALL provide a button to clear import history
