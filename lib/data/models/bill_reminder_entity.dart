import 'package:objectbox/objectbox.dart';

@Entity()
class BillReminderEntity {
  @Id()
  int id = 0;

  @Index()
  String uid;

  String title; // e.g. 'HDFC Credit Card Bill', 'Electricity', 'Airtel Fiber'

  double amount;

  @Index()
  int dueDate; // Epoch ms

  String category; // 'Bills & Utilities', 'Entertainment', 'Investments', etc.

  bool isPaid;

  String recurrence; // 'none', 'weekly', 'monthly', 'yearly'

  String? notes;

  BillReminderEntity({
    this.id = 0,
    required this.uid,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.category = 'Bills & Utilities',
    this.isPaid = false,
    this.recurrence = 'monthly',
    this.notes,
  });

  DateTime get dueDateTime => DateTime.fromMillisecondsSinceEpoch(dueDate);

  bool get isDueToday {
    final now = DateTime.now();
    final due = dueDateTime;
    return now.year == due.year && now.month == due.month && now.day == due.day;
  }

  bool get isOverdue {
    if (isPaid) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDateTime.year, dueDateTime.month, dueDateTime.day);
    return due.isBefore(today);
  }
}
