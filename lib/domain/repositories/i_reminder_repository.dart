import '../../data/models/bill_reminder_entity.dart';

abstract class IReminderRepository {
  List<BillReminderEntity> getAllReminders();
  List<BillReminderEntity> getUpcomingReminders();
  List<BillReminderEntity> getOverdueReminders();
  int addReminder(BillReminderEntity reminder);
  bool updateReminder(BillReminderEntity reminder);
  bool togglePaidStatus(int reminderId, bool isPaid);
  bool deleteReminder(int id);

  const IReminderRepository();
}
