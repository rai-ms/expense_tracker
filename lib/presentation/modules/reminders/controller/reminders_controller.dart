import 'package:flutter/material.dart';

import '../../../../core/services/di/injection.dart';
import '../../../../data/models/bill_reminder_entity.dart';
import '../../../../domain/repositories/i_reminder_repository.dart';
import '../../../blocs/reminders/reminders_bloc.dart';
import '../ui/reminders_view.dart';
import '../ui/widgets/add_reminder_modal.dart';

class RemindersController extends StatefulWidget {
  const RemindersController({super.key});

  @override
  State<RemindersController> createState() => RemindersControllerState();
}

class RemindersControllerState extends State<RemindersController>
    with _RemindersMixin {
  late final RemindersBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = RemindersBloc(sl<IReminderRepository>());
    bloc.add(LoadRemindersEvent());
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RemindersView(this);
  }
}

mixin _RemindersMixin on State<RemindersController> {
  RemindersControllerState get _state => this as RemindersControllerState;

  void onAddNewReminder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddReminderModal(
        onSave: (reminder) {
          _state.bloc.add(AddReminderEvent(reminder));
        },
      ),
    );
  }

  void onTogglePaid(BillReminderEntity reminder, bool isPaid) {
    _state.bloc.add(ToggleReminderPaidEvent(reminder.id, isPaid));
  }

  void onDeleteReminder(int reminderId) {
    _state.bloc.add(DeleteReminderEvent(reminderId));
  }
}
