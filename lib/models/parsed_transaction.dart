enum TransactionType { debit, credit }

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
