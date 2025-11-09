import 'package:shared_preferences/shared_preferences.dart';
import '../app_state.dart';
import '../models/parsed_transaction.dart';
import '../utils/sms_senders.dart';
import '../utils/category_matcher.dart';
import 'sms_service.dart';
import 'sms_parser.dart';

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
      if (_importedSmsIds.contains(sms.id.toString())) continue;

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

    // Save import history
    await saveImportHistory();

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
    await prefs.setString('last_import_date', DateTime.now().toIso8601String());
  }

  // Load imported SMS IDs
  Future<void> loadImportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('imported_sms_ids') ?? [];
    _importedSmsIds.addAll(ids);
  }

  // Get last import date
  Future<DateTime?> getLastImportDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('last_import_date');
    if (dateStr != null) {
      return DateTime.tryParse(dateStr);
    }
    return null;
  }

  // Clear import history
  Future<void> clearImportHistory() async {
    _importedSmsIds.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('imported_sms_ids');
    await prefs.remove('last_import_date');
  }
}
