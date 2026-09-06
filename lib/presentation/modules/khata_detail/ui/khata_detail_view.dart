import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller/widget_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../controller/khata_detail_controller.dart';

class KhataDetailView
    extends WidgetView<KhataDetailView, KhataDetailControllerState> {
  const KhataDetailView(super.state, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    if (ctr.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contact Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final contact = ctr.contact;
    if (contact == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contact Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_rounded, size: 64, color: AppColors.textTertiaryDark),
              const SizedBox(height: 16),
              const Text('Contact not found or was removed'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Khata'),
              ),
            ],
          ),
        ),
      );
    }

    final netBalance = contact.netBalance;
    final entries = contact.entries.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    double totalGave = 0;
    double totalGot = 0;
    for (final e in entries) {
      if (e.isGave) totalGave += e.amount;
      if (e.isGot) totalGot += e.amount;
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Hero(
              tag: 'avatar_${contact.id}',
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(contact.avatarColorValue),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (contact.phoneNumber != null && contact.phoneNumber!.isNotEmpty)
                    Text(
                      contact.phoneNumber!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: ctr.onExportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.bills),
            tooltip: 'Export PDF Statement',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settle') {
                ctr.onSettleAccount();
              } else if (value == 'delete') {
                ctr.onDeleteContact();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settle',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 20, color: AppColors.creditGreen),
                    SizedBox(width: 10),
                    Text('Settle Account'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.debitRed),
                    SizedBox(width: 10),
                    Text('Delete Contact'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Summary Banner Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  netBalance > 0
                      ? AppColors.creditGreen.withValues(alpha: 0.15)
                      : netBalance < 0
                          ? AppColors.debitRed.withValues(alpha: 0.15)
                          : AppColors.darkSurfaceVariant.withValues(alpha: 0.5),
                  AppColors.darkSurfaceVariant.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: netBalance > 0
                    ? AppColors.creditGreen.withValues(alpha: 0.35)
                    : netBalance < 0
                        ? AppColors.debitRed.withValues(alpha: 0.35)
                        : AppColors.darkBorder,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          netBalance > 0
                              ? 'You will receive (Aapko milenge)'
                              : netBalance < 0
                                  ? 'You will give (Aapko dene hain)'
                                  : 'Account is Settled',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currency.format(netBalance.abs()),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: netBalance > 0
                                ? AppColors.creditGreen
                                : netBalance < 0
                                    ? AppColors.debitRed
                                    : AppColors.textPrimaryDark,
                          ),
                        ),
                      ],
                    ),
                    if (netBalance > 0)
                      ElevatedButton.icon(
                        onPressed: () => ctr.onSendWhatsApp(netBalance),
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.creditGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.darkBorder),
                const SizedBox(height: 14),

                // Breakdown: Total Gave vs Total Got
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.debitRed.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_upward_rounded,
                              color: AppColors.debitRed,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Gave (Diye)',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                                ),
                                Text(
                                  currency.format(totalGave),
                                  style: const TextStyle(
                                    fontSize: 14,
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
                    Container(
                      height: 28,
                      width: 1,
                      color: AppColors.darkBorder,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.creditGreen.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_downward_rounded,
                              color: AppColors.creditGreen,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Got (Mile)',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                                ),
                                Text(
                                  currency.format(totalGot),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.creditGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Ledger Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ledger Entries (${entries.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tap entry to manage',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiaryDark,
                  ),
                ),
              ],
            ),
          ),

          // Ledger Entries List
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurfaceVariant.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              size: 48,
                              color: AppColors.textTertiaryDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Entries Yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add your first transaction with this contact using the buttons below',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final isGave = entry.isGave;

                      return InkWell(
                        onTap: () => ctr.onDeleteEntry(entry),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.darkSurfaceVariant.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.darkBorder.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isGave
                                      ? AppColors.debitRed.withValues(alpha: 0.15)
                                      : AppColors.creditGreen.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isGave
                                      ? Icons.arrow_outward_rounded
                                      : Icons.call_received_rounded,
                                  color: isGave ? AppColors.debitRed : AppColors.creditGreen,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isGave
                                          ? 'You Gave (Maine Diye)'
                                          : 'You Got (Mujhe Mile)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                                      Text(
                                        entry.notes!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondaryDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                    ],
                                    Text(
                                      dateFormat.format(entry.dateTime),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textTertiaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    (isGave ? '- ' : '+ ') + currency.format(entry.amount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isGave
                                          ? AppColors.debitRed
                                          : AppColors.creditGreen,
                                    ),
                                  ),
                                  if (entry.isSettled)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.creditGreen.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Settled',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.creditGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Sticky Bottom 2-CTA Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // You Gave (Maine Diye) Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: ctr.onAddGaveEntry,
                      icon: const Icon(Icons.arrow_outward_rounded, size: 20),
                      label: const Text(
                        'YOU GAVE ₹\n(Maine Diye)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.debitRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // You Got (Mujhe Mile) Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: ctr.onAddGotEntry,
                      icon: const Icon(Icons.call_received_rounded, size: 20),
                      label: const Text(
                        'YOU GOT ₹\n(Mujhe Mile)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.creditGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
