# Design Document: SMS Transaction Import

## Overview

This design document outlines the implementation approach for automatic transaction import from SMS messages in the SpendWise Flutter application. The feature will use Android's SMS APIs to read transaction messages from UPI apps and banks, parse transaction details using regex patterns, and automatically sync them with the backend.

## Architecture

### Component Structure

```
lib/
├── services/
│   ├── sms_service.dart                    # NEW: SMS reading and filtering
│   ├── sms_parser.dart                     # NEW: Transaction parsing logic
│   ├── transaction_import_service.dart     # NEW: Import orchestration
│   └── [existing services...]
├── models/
│   ├── parsed_transaction.dart             # NEW: Parsed SMS transaction model
│   ├── sms_sender.dart                     # NEW: Known sender patterns
│   └── [existing models...]
├── screens/
│   ├── sms_import_screen.dart              # NEW: Import preview and confirmation
│   ├── sms_settings_screen.dart            # NEW: SMS import settings
│   └── [existing screens...]
├── widgets/
│   ├── transaction_preview_tile.dart       # NEW: Preview tile for import
│   └── [existing widgets...]
└── utils/
    ├── sms_patterns.dart                   # NEW: Regex patterns for parsing
    └── category_matcher.dart               # NEW: Auto-categorization logic
```

## Components and Interfaces

### 1. SMS Service

#### SmsService
**Purpose**: Handle SMS permission and reading

```dart
class SmsService {
  // Check if SMS permission is granted
  Future<bool> hasPermission() async {
    return await Permission.sms.isGranted;
  }

  // Request SMS permission
  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  // Read SMS messages from inbox
  Future<List<SmsMessage>> readMessages({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? senderAddresses,
  }) async {
    if (!await hasPermission()) {
      throw SmsPermissionException('SMS permission not granted');
    }

    final query = SmsQuery();
    final messages = await query.querySms(
      kinds: [SmsQueryKind.inbox],
      start: startDate?.millisecondsSinceEpoch ?? 0,
      end: endDate?.millisecondsSinceEpoch,
    );

    // Filter by sender if provided
    if (senderAddresses != null && senderAddresses.isNotEmpty) {
      return messages.where((msg) =>
        senderAddresses.any((addr) =>
          msg.address?.toLowerCase().contains(addr.toLowerCase()) ?? false
        )
      ).toList();
    }

    return messages;
  }

  // Filter transaction-related SMS
  List<SmsMessage> filterTransactionSms(List<SmsMessage> messages) {
    final keywords = [
      'debited', 'credited', 'paid', 'sent', 'received',
      'upi', 'transaction', 'payment', 'transfer', 'rs', '₹'
    ];

    return messages.where((msg) {
      final body = msg.body?.toLowerCase() ?? '';
      return keywords.any((keyword) => body.contains(keyword));
    }).toList();
  }
}

class SmsMessage {
  final String? id;
  final String? address;
  final String? body;
  final DateTime? date;
}
```

### 2. SMS Parser

#### SmsParser
**Purpose**: Extract transaction details from SMS text

```dart
class SmsParser {
  // Parse SMS into transaction
  ParsedTransaction? parse(SmsMessage sms) {
    final body = sms.body ?? '';
    
    // Extract amount
    final amount = _extractAmount(body);
    if (amount == null) return null;

    // Extract merchant
    final merchant = _extractMerchant(body);

    // Extract date (use SMS date if not found in body)
    final date = _extractDate(body) ?? sms.date ?? DateTime.now();

    // Extract payment method
    final paymentMethod = _extractPaymentMethod(body);

    // Extract transaction ID
    final transactionId = _extractTransactionId(body);

    // Determine transaction type (debit/credit)
    final type = _extractTransactionType(body);

    return ParsedTransaction(
      amount: amount,
      merchant: merchant,
      date: date,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
      type: type,
      smsId: sms.id,
      smsBody: body,
      sender: sms.address,
    );
  }

  double? _extractAmount(String text) {
    // Patterns for amount extraction
    final patterns = [
      r'(?:rs\.?|inr|₹)\s*(\d+(?:,\d+)*(?:\.\d{2})?)',  // Rs 1,234.56
      r'(\d+(?:,\d+)*(?:\.\d{2})?)\s*(?:rs\.?|inr|₹)',  // 1,234.56 Rs
      r'(?:amount|amt)[\s:]+(?:rs\.?|₹)?\s*(\d+(?:,\d+)*(?:\.\d{2})?)', // Amount: Rs 1234
    ];

    for (final pattern in patterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '';
        return double.tryParse(amountStr);
      }
    }

    return null;
  }

  String _extractMerchant(String text) {
    // Patterns for merchant extraction
    final patterns = [
      r'(?:to|at|from)\s+([A-Z][A-Za-z0-9\s&\-\.]+?)(?:\s+on|\s+for|\s+via|\.|\s+upi)',
      r'(?:paid to|sent to|received from)\s+([A-Z][A-Za-z0-9\s&\-\.]+?)(?:\s+on|\s+for|\.)',
      r'vpa:\s*([a-z0-9\.\-_]+@[a-z]+)',  // UPI ID
    ];

    for (final pattern in patterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim() ?? 'Unknown';
      }
    }

    return 'Unknown';
  }

  DateTime? _extractDate(String text) {
    // Try to extract date from SMS body
    final datePattern = r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})';
    final regex = RegExp(datePattern);
    final match = regex.firstMatch(text);
    
    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        var year = int.parse(match.group(3)!);
        
        // Handle 2-digit year
        if (year < 100) {
          year += 2000;
        }
        
        return DateTime(year, month, day);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  String _extractPaymentMethod(String text) {
    final textLower = text.toLowerCase();
    
    if (textLower.contains('upi')) return 'UPI';
    if (textLower.contains('card')) return 'Card';
    if (textLower.contains('netbanking')) return 'Bank';
    if (textLower.contains('wallet')) return 'Wallet';
    
    return 'UPI'; // Default for most SMS
  }

  String? _extractTransactionId(String text) {
    // UPI transaction ID pattern
    final patterns = [
      r'(?:utr|ref|txn|transaction id)[\s:]+(\d+)',
      r'(\d{12,})', // Long number likely to be transaction ID
    ];

    for (final pattern in patterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  TransactionType _extractTransactionType(String text) {
    final textLower = text.toLowerCase();
    
    if (textLower.contains('debited') || 
        textLower.contains('paid') || 
        textLower.contains('sent')) {
      return TransactionType.debit;
    }
    
    if (textLower.contains('credited') || 
        textLower.contains('received')) {
      return TransactionType.credit;
    }
    
    return TransactionType.debit; // Default
  }
}

enum TransactionType { debit, credit }
```

### 3. Transaction Import Service

#### TransactionImportService
**Purpose**: Orchestrate the import process

```dart
class TransactionImportService {
  final SmsService _smsService;
  final SmsParser _parser;
  final AppState _appState;
  final Set<String> _importedSmsIds = {};

  TransactionImportService(this._smsService, this._parser, this._appState);

  // Scan SMS and return parsed transactions
  Future<List<ParsedTransaction>> scanTransactions({
    int daysBack = 90,
  }) async {
    // Check permission
    if (!await _smsService.hasPermission()) {
      throw SmsPermissionException('SMS permission required');
    }

    // Calculate date range
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: daysBack));

    // Read SMS from known senders
    final senders = SmsSenders.getAllSenders();
    final messages = await _smsService.readMessages(
      startDate: startDate,
      endDate: endDate,
      senderAddresses: senders,
    );

    // Filter transaction SMS
    final transactionSms = _smsService.filterTransactionSms(messages);

    // Parse transactions
    final parsed = <ParsedTransaction>[];
    for (final sms in transactionSms) {
      // Skip if already imported
      if (_importedSmsIds.contains(sms.id)) continue;

      final transaction = _parser.parse(sms);
      if (transaction != null && transaction.type == TransactionType.debit) {
        // Only import debits (expenses)
        parsed.add(transaction);
      }
    }

    return parsed;
  }

  // Check for duplicates
  bool isDuplicate(ParsedTransaction parsed) {
    final existing = _appState.transactions;
    
    for (final tx in existing) {
      // Check if amount, date (within 1 min), and merchant match
      final amountMatch = (tx.amount - parsed.amount).abs() < 0.01;
      final dateMatch = tx.time.difference(parsed.date).inMinutes.abs() <= 1;
      final merchantMatch = tx.merchant.toLowerCase() == parsed.merchant.toLowerCase();
      
      if (amountMatch && dateMatch && merchantMatch) {
        return true;
      }
    }

    return false;
  }

  // Import transactions
  Future<ImportResult> importTransactions(List<ParsedTransaction> transactions) async {
    int successful = 0;
    int failed = 0;
    int skipped = 0;
    final errors = <String>[];

    for (final parsed in transactions) {
      try {
        // Check for duplicates
        if (isDuplicate(parsed)) {
          skipped++;
          continue;
        }

        // Auto-categorize
        final category = CategoryMatcher.matchCategory(parsed.merchant);

        // Add to backend
        await _appState.addExpense(
          amount: parsed.amount,
          category: category,
          merchant: parsed.merchant,
          source: parsed.paymentMethod,
        );

        // Mark as imported
        if (parsed.smsId != null) {
          _importedSmsIds.add(parsed.smsId!);
        }

        successful++;
      } catch (e) {
        failed++;
        errors.add('Failed to import ${parsed.merchant}: ${e.toString()}');
      }
    }

    return ImportResult(
      successful: successful,
      failed: failed,
      skipped: skipped,
      errors: errors,
    );
  }

  // Save imported SMS IDs to prevent re-import
  Future<void> saveImportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('imported_sms_ids', _importedSmsIds.toList());
  }

  // Load imported SMS IDs
  Future<void> loadImportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('imported_sms_ids') ?? [];
    _importedSmsIds.addAll(ids);
  }
}

class ImportResult {
  final int successful;
  final int failed;
  final int skipped;
  final List<String> errors;

  ImportResult({
    required this.successful,
    required this.failed,
    required this.skipped,
    required this.errors,
  });
}
```

### 4. Category Matcher

#### CategoryMatcher
**Purpose**: Auto-categorize transactions based on merchant name

```dart
class CategoryMatcher {
  static final Map<CategoryType, List<String>> _keywords = {
    CategoryType.food: [
      'swiggy', 'zomato', 'uber eats', 'dominos', 'pizza', 'restaurant',
      'cafe', 'food', 'mcdonald', 'kfc', 'subway', 'starbucks', 'dunkin'
    ],
    CategoryType.travel: [
      'uber', 'ola', 'rapido', 'irctc', 'makemytrip', 'goibibo', 'redbus',
      'flight', 'hotel', 'cab', 'taxi', 'petrol', 'fuel', 'parking'
    ],
    CategoryType.shopping: [
      'amazon', 'flipkart', 'myntra', 'ajio', 'meesho', 'snapdeal',
      'shopping', 'mall', 'store', 'retail', 'fashion', 'clothing'
    ],
    CategoryType.luxuries: [
      'netflix', 'prime', 'hotstar', 'spotify', 'youtube', 'subscription',
      'gaming', 'entertainment', 'movie', 'cinema', 'pvr', 'inox'
    ],
  };

  static CategoryType matchCategory(String merchant) {
    final merchantLower = merchant.toLowerCase();

    for (final entry in _keywords.entries) {
      if (entry.value.any((keyword) => merchantLower.contains(keyword))) {
        return entry.key;
      }
    }

    return CategoryType.other;
  }
}
```

### 5. Known SMS Senders

#### SmsSenders
**Purpose**: Maintain list of known payment app and bank sender addresses

```dart
class SmsSenders {
  static const List<String> paymentApps = [
    'GPAY',      // Google Pay
    'PHONEPE',   // PhonePe
    'PAYTM',     // Paytm
    'AMAZONPAY', // Amazon Pay
    'MOBIKWIK',  // MobiKwik
    'FREECHARGE',// FreeCharge
    'BHIM',      // BHIM UPI
  ];

  static const List<String> banks = [
    'HDFCBK',    // HDFC Bank
    'ICICIB',    // ICICI Bank
    'SBIIN',     // State Bank of India
    'AXISBK',    // Axis Bank
    'KOTAKBK',   // Kotak Bank
    'PNBSMS',    // Punjab National Bank
    'BOISMS',    // Bank of India
    'CBSSBI',    // SBI
    'IDFCBK',    // IDFC First Bank
  ];

  static List<String> getAllSenders() {
    return [...paymentApps, ...banks];
  }
}
```

## Data Models

### ParsedTransaction
```dart
class ParsedTransaction {
  final double amount;
  final String merchant;
  final DateTime date;
  final String paymentMethod;
  final String? transactionId;
  final TransactionType type;
  final String? smsId;
  final String? smsBody;
  final String? sender;

  ParsedTransaction({
    required this.amount,
    required this.merchant,
    required this.date,
    required this.paymentMethod,
    this.transactionId,
    required this.type,
    this.smsId,
    this.smsBody,
    this.sender,
  });
}
```

## UI Screens

### 1. SMS Import Screen

**Purpose**: Preview and confirm transactions before import

**UI Layout**:
- Header showing count of found transactions
- List of transaction preview tiles
- Each tile shows: amount, merchant, date, suggested category
- Checkbox to select/deselect transactions
- Bottom bar with "Import Selected" button
- Progress indicator during import
- Success/error summary dialog

### 2. SMS Settings Screen

**Purpose**: Configure SMS import settings

**UI Layout**:
- Enable/Disable SMS Import toggle
- SMS Permission status indicator
- "Grant Permission" button (if not granted)
- Date range selector (30/60/90 days)
- Last import timestamp
- "Import Now" button
- Import history section
- Clear history button

## Error Handling

### Permission Errors
- Show dialog explaining why SMS permission is needed
- Provide button to open app settings
- Gracefully disable feature if permission denied

### Parsing Errors
- Log failed SMS for debugging
- Continue processing other messages
- Show count of unparseable messages in summary

### Backend Sync Errors
- Retry failed imports up to 3 times
- Save failed transactions locally
- Show error details to user
- Provide manual retry option

## Privacy and Security

### Data Handling
- SMS content processed locally on device
- Only parsed transaction data sent to backend
- No full SMS content stored or transmitted
- SMS IDs stored locally to prevent re-import

### User Control
- Clear permission request with explanation
- Easy way to revoke permission
- Option to disable feature completely
- Transparent about what data is collected

## Testing Strategy

### Unit Tests
- SMS parsing with various formats
- Duplicate detection logic
- Category matching algorithm
- Date extraction edge cases

### Integration Tests
- End-to-end import flow
- Permission handling
- Backend sync
- Error recovery

### Manual Testing
- Test with real SMS from different apps
- Test with different phone models
- Test permission flows
- Test with large SMS volumes

## Performance Considerations

### SMS Reading
- Limit date range to avoid reading too many messages
- Filter by sender to reduce processing
- Process in batches if large volume

### Parsing
- Use efficient regex patterns
- Cache compiled regex
- Process asynchronously

### Memory
- Don't load all SMS at once
- Clear processed messages from memory
- Limit import history size

## Dependencies

```yaml
dependencies:
  permission_handler: ^11.0.0  # Permission management
  sms_advanced: ^1.0.0         # SMS reading (or telephony package)
  shared_preferences: ^2.2.0   # Store import history
```

## Future Enhancements

- Machine learning for better categorization
- Support for credit card SMS
- Bank statement parsing
- Receipt OCR integration
- Multi-language SMS support
- Custom parsing rules
