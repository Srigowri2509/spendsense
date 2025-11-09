import 'package:permission_handler/permission_handler.dart';

class SmsPermissionException implements Exception {
  final String message;
  SmsPermissionException(this.message);
  
  @override
  String toString() => message;
}

class SmsMessage {
  final int? id;
  final String? address;
  final String? body;
  final DateTime? date;

  SmsMessage({this.id, this.address, this.body, this.date});
}

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

    try {
      // Note: flutter_sms doesn't have direct inbox reading
      // This is a placeholder - in production, you'd use platform channels
      // or a different package that supports SMS reading
      
      // For now, return empty list to prevent crashes
      // You can implement platform-specific code later
      return [];
    } catch (e) {
      throw SmsPermissionException('Failed to read SMS: ${e.toString()}');
    }
  }

  // Filter transaction-related SMS
  List<SmsMessage> filterTransactionSms(List<SmsMessage> messages) {
    final keywords = [
      'debited', 'credited', 'paid', 'sent', 'received',
      'upi', 'transaction', 'payment', 'transfer', 'rs', '₹', 'inr'
    ];

    return messages.where((msg) {
      final body = msg.body?.toLowerCase() ?? '';
      return keywords.any((keyword) => body.contains(keyword));
    }).toList();
  }
}
