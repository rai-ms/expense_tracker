import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller/widget_view.dart';
import '../../../../core/base/bloc_base/bloc_event_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/khata_bloc.dart';
import '../controller/khata_controller.dart';
import '../../settings/ui/language_selection_modal.dart';
import 'widgets/split_bill_modal.dart';

import '../../../../core/localization/app_localizations.dart';

class KhataView extends WidgetView<KhataView, KhataControllerState> {
  const KhataView(super.ctr, {super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.tr('khata_ledger'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: () => SplitBillModal.show(context: context),
            icon: const Icon(Icons.call_split_rounded, color: AppColors.secondary),
            tooltip: 'Split Bill with Friends',
          ),
          IconButton(
            onPressed: () => LanguageSelectionModal.show(context),
            icon: const Icon(Icons.translate_rounded, color: AppColors.primaryLight),
            tooltip: 'Change Language / भाषा बदलें',
          ),
          IconButton(
            onPressed: ctr.onAddNewContact,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: context.tr('add_customer'),
          ),
        ],
      ),
      body: BlocBuilder<KhataBloc, BlocEventState<KhataData>>(
        bloc: ctr.bloc,
        builder: (context, state) {
          final data = state.data;
          final contacts = data?.contacts ?? [];

          return Column(
            children: [
              // Overall Udhar Summary Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Row(
                    children: [
                      // Will Receive
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('you_will_receive'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currency.format(data?.totalWillReceive ?? 0.0),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.creditGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 48,
                        color: AppColors.darkBorder,
                      ),
                      const SizedBox(width: 16),
                      // Will Give
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('you_will_give'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currency.format(data?.totalWillGive ?? 0.0),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.debitRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Action: Split a Bill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => SplitBillModal.show(context: context),
                    icon: const Icon(Icons.call_split_rounded, size: 18, color: AppColors.secondary),
                    label: const Text('Split a Bill with Friends 👥', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary, width: 0.8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Contacts List
              Expanded(
                child: state.isLoading && contacts.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : contacts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 56,
                                  color: AppColors.textTertiaryDark.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  context.tr('no_entries'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ElevatedButton.icon(
                                  onPressed: ctr.onAddNewContact,
                                  icon: const Icon(Icons.person_add_rounded, size: 16),
                                  label: Text(context.tr('add_customer')),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            physics: const BouncingScrollPhysics(),
                            itemCount: contacts.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final contact = contacts[index];
                              final netBalance = contact.netBalance;

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => ctr.onContactTap(contact),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardTheme.color,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.darkBorder.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Color(contact.avatarColorValue),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            contact.name.isNotEmpty
                                                ? contact.name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                contact.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${contact.entries.length} transactions',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textSecondaryDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              currency.format(netBalance.abs()),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: netBalance > 0
                                                    ? AppColors.creditGreen
                                                    : netBalance < 0
                                                        ? AppColors.debitRed
                                                        : AppColors.textTertiaryDark,
                                              ),
                                            ),
                                            Text(
                                              netBalance > 0
                                                  ? 'Aapko milenge'
                                                  : netBalance < 0
                                                      ? 'Aapko dene hain'
                                                      : 'Settled',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: netBalance > 0
                                                    ? AppColors.creditGreen
                                                    : netBalance < 0
                                                        ? AppColors.debitRed
                                                        : AppColors.textTertiaryDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_khata',
        onPressed: ctr.onAddNewContact,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('New Contact'),
      ),
    );
  }
}
