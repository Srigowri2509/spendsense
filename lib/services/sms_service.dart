import 'dart:io';

import 'package:flutter_sms_inbox/flutter_sms_inbox.dart' as inbox;
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
  const SmsService();

  inbox.SmsQuery? get _query =>
      Platform.isAndroid ? inbox.SmsQuery() : null;

  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return false;
    return await Permission.sms.isGranted;
  }

  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  // Read SMS messages from inbox
  Future<List<SmsMessage>> readMessages({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? senderAddresses,
  }) async {
    if (!Platform.isAndroid) {
      return [];
    }

    if (!await hasPermission()) {
      throw SmsPermissionException('SMS permission not granted');
    }

    try {
      final q = _query;
      if (q == null) return [];

      final List<inbox.SmsMessage> rawMessages = [];

      if (senderAddresses != null && senderAddresses.isNotEmpty) {
        for (final addr in senderAddresses) {
          final msgs = await q.querySms(
            address: addr,
            kinds: const [inbox.SmsQueryKind.inbox],
            sort: true,
          );
          rawMessages.addAll(msgs);
        }
      } else {
        rawMessages.addAll(
          await q.querySms(
            kinds: const [inbox.SmsQueryKind.inbox],
            sort: true,
          ),
        );
      }

      final filtered = rawMessages.where((m) {
        final date = m.date;
        if (startDate != null && date != null && date.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && date != null && date.isAfter(endDate)) {
          return false;
        }
        if (senderAddresses != null && senderAddresses.isNotEmpty) {
          final addr = (m.address ?? '').toLowerCase();
          return senderAddresses.any((s) => addr == s.toLowerCase());
        }
        return true;
      });

      return filtered
          .map(
            (m) => SmsMessage(
              id: m.id,
              address: m.address,
              body: m.body,
              date: m.date,
            ),
          )
          .toList();
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
