import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller/widget_view.dart';
import '../../../../core/base/bloc_base/bloc_event_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/reminders_bloc.dart';
import '../controller/reminders_controller.dart';

class RemindersView extends WidgetView<RemindersView, RemindersControllerState> {
  const RemindersView(super.ctr, {super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Bill & Payment Reminders',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: ctr.onAddNewReminder,
            icon: const Icon(Icons.add_alert_rounded),
            tooltip: 'Add Reminder',
          ),
        ],
      ),
      body: BlocBuilder<RemindersBloc, BlocEventState<RemindersData>>(
        bloc: ctr.bloc,
        builder: (context, state) {
          final data = state.data;
          final reminders = data?.reminders ?? [];

          if (state.isLoading && reminders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 56,
                    color: AppColors.textTertiaryDark.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No bill reminders set',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Never miss credit card or utility bill dues again!',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: reminders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              final catMeta = AppConstants.getCategory(reminder.category);
              final catColor = catMeta['color'] as Color;
              final catIcon = catMeta['icon'] as IconData;

              final isOverdue = reminder.isOverdue;
              final isDueToday = reminder.isDueToday;
              final isPaid = reminder.isPaid;

              final statusColor = isPaid
                  ? AppColors.creditGreen
                  : isOverdue
                      ? AppColors.debitRed
                      : isDueToday
                          ? AppColors.warningAmber
                          : AppColors.primary;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOverdue
                        ? AppColors.debitRed.withValues(alpha: 0.5)
                        : AppColors.darkBorder.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(catIcon, color: catColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              decoration: isPaid ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPaid
                                      ? 'Paid'
                                      : isOverdue
                                          ? 'Overdue'
                                          : isDueToday
                                              ? 'Due Today'
                                              : 'Due ${dateFormat.format(reminder.dueDateTime)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currency.format(reminder.amount),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: reminder.isPaid,
                      activeColor: AppColors.creditGreen,
                      onChanged: (val) {
                        if (val != null) {
                          ctr.onTogglePaid(reminder, val);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_reminders',
        onPressed: ctr.onAddNewReminder,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
