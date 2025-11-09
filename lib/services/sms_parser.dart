import '../models/parsed_transaction.dart';
import 'sms_service.dart';

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
      smsId: sms.id.toString(),
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
      r'(?:debited|credited|paid|sent|received)[\s:]+(?:rs\.?|₹)?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
    ];

    for (final pattern in patterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '';
        final parsed = double.tryParse(amountStr);
        if (parsed != null && parsed > 0) {
          return parsed;
        }
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
      r'(?:merchant|vendor)[\s:]+([A-Za-z0-9\s&\-\.]+?)(?:\s+on|\.)',
    ];

    for (final pattern in patterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) {
        final merchant = match.group(1)?.trim() ?? '';
        if (merchant.isNotEmpty && merchant.length > 2) {
          return merchant;
        }
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
    if (textLower.contains('netbanking') || textLower.contains('net banking')) return 'Bank';
    if (textLower.contains('wallet')) return 'Wallet';
    if (textLower.contains('imps') || textLower.contains('neft') || textLower.contains('rtgs')) return 'Bank';
    
    return 'UPI'; // Default for most SMS
  }

  String? _extractTransactionId(String text) {
    // UPI transaction ID pattern
    final patterns = [
      r'(?:utr|ref|txn|transaction id|ref no)[\s:]+(\d+)',
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
        textLower.contains('sent') ||
        textLower.contains('deducted')) {
      return TransactionType.debit;
    }
    
    if (textLower.contains('credited') || 
        textLower.contains('received') ||
        textLower.contains('deposited')) {
      return TransactionType.credit;
    }
    
    return TransactionType.debit; // Default
  }
}
