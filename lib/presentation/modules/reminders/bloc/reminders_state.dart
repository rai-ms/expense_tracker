part of 'reminders_bloc.dart';

/// State data class holding all reminder categories
class RemindersData {
  final List<BillReminderEntity> reminders;
  final List<BillReminderEntity> upcoming;
  final List<BillReminderEntity> overdue;

  const RemindersData({
    required this.reminders,
    required this.upcoming,
    required this.overdue,
  });
}
