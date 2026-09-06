part of 'reminders_bloc.dart';

/// Base class for Bill Reminders events
abstract class RemindersEvent extends BlocEvent {
  const RemindersEvent();
}

/// Event to load all upcoming, overdue, and paid reminders
class LoadRemindersEvent extends RemindersEvent {}

/// Event to create a new reminder
class AddReminderEvent extends RemindersEvent {
  final BillReminderEntity reminder;
  const AddReminderEvent(this.reminder);

  @override
  List<Object?> get props => [reminder];
}

/// Event to toggle the paid status of a reminder
class ToggleReminderPaidEvent extends RemindersEvent {
  final int reminderId;
  final bool isPaid;
  const ToggleReminderPaidEvent(this.reminderId, this.isPaid);

  @override
  List<Object?> get props => [reminderId, isPaid];
}

/// Event to delete a reminder
class DeleteReminderEvent extends RemindersEvent {
  final int reminderId;
  const DeleteReminderEvent(this.reminderId);

  @override
  List<Object?> get props => [reminderId];
}
