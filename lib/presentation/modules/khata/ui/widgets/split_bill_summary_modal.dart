import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/di/injection.dart';
import '../../../../../core/services/split_bill_service/split_bill_service.dart';

/// Modal displaying the completed Split Bill breakdown with 1-tap WhatsApp reminders
class SplitBillSummaryModal extends StatefulWidget {
  final SplitBillResult result;
  final String title;
  final double totalAmount;

  const SplitBillSummaryModal({
    super.key,
    required this.result,
    required this.title,
    required this.totalAmount,
  });

  static Future<void> show({
    required BuildContext context,
    required SplitBillResult result,
    required String title,
    required double totalAmount,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SplitBillSummaryModal(
        result: result,
        title: title,
        totalAmount: totalAmount,
      ),
    );
  }

  @override
  State<SplitBillSummaryModal> createState() => _SplitBillSummaryModalState();
}

class _SplitBillSummaryModalState extends State<SplitBillSummaryModal> {
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _upiController = TextEditingController();
  late final SplitBillService _splitBillService;

  @override
  void initState() {
    super.initState();
    _splitBillService = sl<SplitBillService>();
    _upiController.text = _splitBillService.getUserUpiId();
  }

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  void _saveUpiId() {
    final upi = _upiController.text.trim();
    _splitBillService.setUserUpiId(upi);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(upi.isEmpty ? 'UPI ID cleared' : 'UPI ID saved: $upi'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final friends = widget.result.participants.where((p) => !p.isCurrentUser).toList();
    final userParticipant = widget.result.participants.firstWhere(
      (p) => p.isCurrentUser,
      orElse: () => widget.result.participants.first,
    );

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.creditGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.creditGreen, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bill Split Recorded! 💸',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  // Total and Personal Share Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.primaryLight.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Bill',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currency.format(widget.totalAmount),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: Colors.white24,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Your Share (Expense)',
                              style: TextStyle(fontSize: 12, color: AppColors.primaryLight),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currency.format(userParticipant.shareAmount),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // UPI ID Configuration Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceVariant.withValues(alpha: 0.4) : AppColors.lightSurfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_rounded, size: 18, color: AppColors.primaryLight),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _upiController,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Your UPI ID (e.g. name@okhdfcbank)',
                              hintStyle: TextStyle(fontSize: 12, color: Colors.white38),
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (_) => _saveUpiId(),
                          ),
                        ),
                        InkWell(
                          onTap: _saveUpiId,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Friends Shares & WhatsApp Reminders
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Friends Owning Share (Added to Khata)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${friends.length} friend${friends.length > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ...friends.map((friend) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant.withValues(alpha: 0.3) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            child: Text(
                              friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  friend.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Owes you ${_currency.format(friend.shareAmount)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.creditGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              _splitBillService.shareReminder(
                                friendName: friend.name,
                                amount: friend.shareAmount,
                                description: widget.title,
                                phoneNumber: friend.phoneNumber,
                                upiId: _upiController.text.trim(),
                              );
                            },
                            icon: const Icon(Icons.send_rounded, size: 14),
                            label: const Text('Remind'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366), // WhatsApp Brand Green
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Done Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
