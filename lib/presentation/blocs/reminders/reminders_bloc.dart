import '../../../core/base/bloc_base/base_bloc.dart';
import '../../../core/base/bloc_base/bloc_event.dart';
import '../../../core/services/event_bus/app_events.dart';
import '../../../data/models/bill_reminder_entity.dart';
import '../../../domain/repositories/i_reminder_repository.dart';

// Reminders Events
abstract class RemindersEvent extends BlocEvent {
  const RemindersEvent();
}

class LoadRemindersEvent extends RemindersEvent {}

class AddReminderEvent extends RemindersEvent {
  final BillReminderEntity reminder;
  const AddReminderEvent(this.reminder);

  @override
  List<Object?> get props => [reminder];
}

class ToggleReminderPaidEvent extends RemindersEvent {
  final int reminderId;
  final bool isPaid;
  const ToggleReminderPaidEvent(this.reminderId, this.isPaid);

  @override
  List<Object?> get props => [reminderId, isPaid];
}

class DeleteReminderEvent extends RemindersEvent {
  final int reminderId;
  const DeleteReminderEvent(this.reminderId);

  @override
  List<Object?> get props => [reminderId];
}

// Reminders State Data
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

// Reminders BLoC
class RemindersBloc extends BaseBloc<RemindersEvent, RemindersData> {
  final IReminderRepository _reminderRepository;

  RemindersBloc(this._reminderRepository) {
    on<LoadRemindersEvent>(_onLoadReminders);
    on<AddReminderEvent>(_onAddReminder);
    on<ToggleReminderPaidEvent>(_onTogglePaid);
    on<DeleteReminderEvent>(_onDeleteReminder);
  }

  void _onLoadReminders(
    LoadRemindersEvent event,
    dynamic emit,
  ) {
    emitLoading();
    try {
      final all = _reminderRepository.getAllReminders();
      final upcoming = _reminderRepository.getUpcomingReminders();
      final overdue = _reminderRepository.getOverdueReminders();

      emitSuccess(
        data: RemindersData(
          reminders: all,
          upcoming: upcoming,
          overdue: overdue,
        ),
      );
    } catch (e) {
      emitFailed(message: 'Failed to load bill reminders: $e');
    }
  }

  void _onAddReminder(
    AddReminderEvent event,
    dynamic emit,
  ) {
    try {
      _reminderRepository.addReminder(event.reminder);
      AppEvents.notifyDataChanged();
      add(LoadRemindersEvent());
    } catch (e) {
      emitFailed(message: 'Failed to add reminder: $e');
    }
  }

  void _onTogglePaid(
    ToggleReminderPaidEvent event,
    dynamic emit,
  ) {
    try {
      _reminderRepository.togglePaidStatus(event.reminderId, event.isPaid);
      AppEvents.notifyDataChanged();
      add(LoadRemindersEvent());
    } catch (e) {
      emitFailed(message: 'Failed to update reminder status: $e');
    }
  }

  void _onDeleteReminder(
    DeleteReminderEvent event,
    dynamic emit,
  ) {
    try {
      _reminderRepository.deleteReminder(event.reminderId);
      AppEvents.notifyDataChanged();
      add(LoadRemindersEvent());
    } catch (e) {
      emitFailed(message: 'Failed to delete reminder: $e');
    }
  }
}
