import 'package:objectbox/objectbox.dart';

@Entity()
class TransactionEntity {
  @Id()
  int id = 0;

  @Index()
  String uid; // Unique string UUID or SMS hash

  double amount;

  @Index()
  String type; // 'debit' or 'credit'

  @Index()
  String category; // 'Food & Dining', 'Groceries', etc.

  String? merchant; // 'Swiggy', 'Zomato', 'Amazon', etc.

  @Index()
  String? platform; // 'Google Pay', 'PhonePe', 'HDFC Bank', etc.

  @Index()
  String? transactionId; // UTR or Ref number

  String? accountOrCard; // Last 4 digits (e.g. '1234')

  @Index()
  int date; // Epoch timestamp in milliseconds

  String? rawSms;

  double? balanceAfter;

  String? notes;

  bool isAutomated; // true if auto-parsed from SMS, false if manual

  @Index()
  bool isIgnored; // true if marked as notification only / ignored

  String? receiptPath; // Local path to attached receipt photo

  TransactionEntity({
    this.id = 0,
    required this.uid,
    required this.amount,
    required this.type,
    required this.category,
    this.merchant,
    this.platform,
    this.transactionId,
    this.accountOrCard,
    required this.date,
    this.rawSms,
    this.balanceAfter,
    this.notes,
    this.isAutomated = false,
    this.isIgnored = false,
    this.receiptPath,
  });

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(date);
  bool get isDebit => type.toLowerCase() == 'debit';
  bool get isCredit => type.toLowerCase() == 'credit';
  bool get hasReceipt => receiptPath != null && receiptPath!.isNotEmpty;
}
