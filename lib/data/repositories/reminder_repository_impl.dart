import '../../core/services/objectbox_service/objectbox_service.dart';
import '../../domain/repositories/i_reminder_repository.dart';
import '../../objectbox.g.dart';
import '../models/bill_reminder_entity.dart';

class ReminderRepositoryImpl implements IReminderRepository {
  final ObjectBoxService _boxService;

  const ReminderRepositoryImpl(this._boxService);

  @override
  List<BillReminderEntity> getAllReminders() {
    final query = _boxService.billReminderBox.query()
      ..order(BillReminderEntity_.dueDate);
    final q = query.build();
    final results = q.find();
    q.close();
    return results;
  }

  @override
  List<BillReminderEntity> getUpcomingReminders() {
    final all = getAllReminders();
    return all.where((r) => !r.isPaid).toList();
  }

  @override
  List<BillReminderEntity> getOverdueReminders() {
    final all = getAllReminders();
    return all.where((r) => r.isOverdue).toList();
  }

  @override
  int addReminder(BillReminderEntity reminder) {
    return _boxService.billReminderBox.put(reminder);
  }

  @override
  bool updateReminder(BillReminderEntity reminder) {
    _boxService.billReminderBox.put(reminder);
    return true;
  }

  @override
  bool togglePaidStatus(int reminderId, bool isPaid) {
    final reminder = _boxService.billReminderBox.get(reminderId);
    if (reminder == null) return false;
    reminder.isPaid = isPaid;
    _boxService.billReminderBox.put(reminder);
    return true;
  }

  @override
  bool deleteReminder(int id) {
    return _boxService.billReminderBox.remove(id);
  }
}
