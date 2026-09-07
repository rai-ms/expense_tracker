import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/services/di/injection.dart';
import '../../../../../core/services/split_bill_service/split_bill_service.dart';
import '../../../../../data/models/khata_contact_entity.dart';
import '../../../../../domain/repositories/i_khata_repository.dart';
import 'split_bill_summary_modal.dart';

/// Modal bottom sheet for splitting an expense bill among friends and recording it in KhataBook
class SplitBillModal extends StatefulWidget {
  final double? initialAmount;
  final String? initialTitle;
  final String? initialCategory;
  final int? existingTransactionId;

  const SplitBillModal({
    super.key,
    this.initialAmount,
    this.initialTitle,
    this.initialCategory,
    this.existingTransactionId,
  });

  static Future<void> show({
    required BuildContext context,
    double? initialAmount,
    String? initialTitle,
    String? initialCategory,
    int? existingTransactionId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SplitBillModal(
        initialAmount: initialAmount,
        initialTitle: initialTitle,
        initialCategory: initialCategory,
        existingTransactionId: existingTransactionId,
      ),
    );
  }

  @override
  State<SplitBillModal> createState() => _SplitBillModalState();
}

class _SplitBillModalState extends State<SplitBillModal> {
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  late final TextEditingController _amountController;
  late final TextEditingController _titleController;

  SplitMode _splitMode = SplitMode.equal;
  late String _selectedCategory;

  final List<SplitParticipant> _participants = [];
  List<KhataContactEntity> _allKhataContacts = [];
  bool _isLoading = false;

  final Map<String, TextEditingController> _exactControllers = {};
  final Map<String, TextEditingController> _percentControllers = {};

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount != null && widget.initialAmount! > 0
          ? widget.initialAmount!.toInt().toString()
          : '',
    );
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _selectedCategory = widget.initialCategory ?? 'Food & Dining';

    _loadContacts();
  }

  void _loadContacts() {
    final khataRepo = sl<IKhataRepository>();
    final contacts = khataRepo.getAllContacts();

    final splitService = sl<SplitBillService>();
    final userName = splitService.getUserDisplayName();

    setState(() {
      _allKhataContacts = contacts;
      // Initialize with current user
      _participants.clear();
      _participants.add(
        SplitParticipant(
          name: userName,
          isCurrentUser: true,
        ),
      );
      _recalculateShares();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    for (final c in _exactControllers.values) {
      c.dispose();
    }
    for (final c in _percentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalAmount => double.tryParse(_amountController.text.trim()) ?? 0.0;

  void _recalculateShares() {
    final splitService = sl<SplitBillService>();
    if (_splitMode == SplitMode.equal) {
      final updated = splitService.computeEqualShares(_totalAmount, _participants);
      _participants.clear();
      _participants.addAll(updated);
    } else if (_splitMode == SplitMode.percentage) {
      final updated = splitService.computePercentageShares(_totalAmount, _participants);
      _participants.clear();
      _participants.addAll(updated);
    }
  }

  void _toggleContact(KhataContactEntity contact) {
    setState(() {
      final existingIndex = _participants.indexWhere((p) => p.contactId == contact.id);
      if (existingIndex >= 0) {
        _participants.removeAt(existingIndex);
      } else {
        _participants.add(
          SplitParticipant(
            contactId: contact.id,
            name: contact.name,
            phoneNumber: contact.phoneNumber,
          ),
        );
      }
      _recalculateShares();
    });
  }

  void _openAddContactDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, color: AppColors.primaryLight, size: 22),
            SizedBox(width: 8),
            Text('Add Friend to Split', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Friend Name *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number (Optional for WhatsApp)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              setState(() {
                _participants.add(
                  SplitParticipant(
                    name: name,
                    phoneNumber: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                  ),
                );
                _recalculateShares();
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Add to Split'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitSplit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description for this bill')),
      );
      return;
    }

    if (_totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid bill amount')),
      );
      return;
    }

    if (_participants.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one friend to split with')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final splitService = sl<SplitBillService>();
    final request = SplitBillRequest(
      totalAmount: _totalAmount,
      title: title,
      category: _selectedCategory,
      mode: _splitMode,
      participants: _participants,
      existingTransactionId: widget.existingTransactionId,
    );

    final result = await splitService.recordSplitBill(request);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      Navigator.pop(context); // Close split modal
      SplitBillSummaryModal.show(
        context: context,
        result: result,
        title: title,
        totalAmount: _totalAmount,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: AppColors.debitRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allCategories = AppConstants.getAllCategories();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.8,
          ),
        ),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          children: [
            // Drag handle
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
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.call_split_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Split Bill with Friends',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Auto-records shares in Khata & sends UPI reminders',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  // 1. Total Bill Amount Input
                  const Text(
                    'Total Bill Amount',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '₹',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              hintText: '0',
                              border: InputBorder.none,
                            ),
                            onChanged: (_) {
                              setState(() {
                                _recalculateShares();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Bill Description / Title
                  const Text(
                    'Bill Description / Merchant',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'e.g. Swiggy Dinner, Flat Rent, Weekend Trip',
                      prefixIcon: const Icon(Icons.receipt_long_rounded, size: 20),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Category Selector
                  const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: allCategories.take(8).map((cat) {
                        final catName = cat['name'] as String? ?? 'General';
                        final catIcon = cat['icon'] as IconData? ?? Icons.category_rounded;
                        final catColor = cat['color'] as Color? ?? AppColors.primary;
                        final isSelected = _selectedCategory == catName;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: Icon(catIcon, size: 16, color: isSelected ? Colors.white : catColor),
                            label: Text(catName, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            onSelected: (val) {
                              if (val) setState(() => _selectedCategory = catName);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. Participant Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Participants',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      TextButton.icon(
                        onPressed: _openAddContactDialog,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Friend', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),

                  // Khata Contacts Quick Selection Row
                  if (_allKhataContacts.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _allKhataContacts.map((c) {
                          final isSelected = _participants.any((p) => p.contactId == c.id);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              avatar: CircleAvatar(
                                radius: 10,
                                backgroundColor: Color(c.avatarColorValue),
                                child: Text(
                                  c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              label: Text(c.name, style: const TextStyle(fontSize: 12)),
                              selected: isSelected,
                              selectedColor: AppColors.primary.withValues(alpha: 0.25),
                              onSelected: (_) => _toggleContact(c),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // 5. Split Mode Switcher
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildModeTab('Equally', SplitMode.equal),
                        _buildModeTab('Exact ₹', SplitMode.exact),
                        _buildModeTab('% Share', SplitMode.percentage),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 6. Calculated Participant Shares
                  ..._participants.map((p) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant.withValues(alpha: 0.4) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: p.isCurrentUser
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: p.isCurrentUser
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.15),
                            child: p.isCurrentUser
                                ? const Icon(Icons.person_rounded, size: 18, color: Colors.white)
                                : Text(
                                    p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: AppColors.primaryLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    if (p.isCurrentUser) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text('You', style: TextStyle(fontSize: 10, color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                                if (_splitMode == SplitMode.equal)
                                  Text(
                                    '${p.percentage.toStringAsFixed(0)}% of bill',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                                  ),
                              ],
                            ),
                          ),
                          if (_splitMode == SplitMode.equal)
                            Text(
                              _currency.format(p.shareAmount),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            )
                          else if (_splitMode == SplitMode.exact)
                            SizedBox(
                              width: 90,
                              child: TextField(
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                decoration: const InputDecoration(
                                  prefixText: '₹',
                                  isDense: true,
                                  border: UnderlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  final amt = double.tryParse(val) ?? 0.0;
                                  p.shareAmount = amt;
                                  setState(() {});
                                },
                              ),
                            )
                          else
                            SizedBox(
                              width: 80,
                              child: TextField(
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                decoration: const InputDecoration(
                                  suffixText: '%',
                                  isDense: true,
                                  border: UnderlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  final pct = double.tryParse(val) ?? 0.0;
                                  p.percentage = pct;
                                  _recalculateShares();
                                  setState(() {});
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Confirm Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitSplit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm & Record in Khata', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(String label, SplitMode mode) {
    final isSelected = _splitMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _splitMode = mode;
            _recalculateShares();
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }
}
