import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/services/di/injection.dart';
import '../../../../../core/services/receipt_service/receipt_service.dart';
import '../../../../../data/models/transaction_entity.dart';
import '../../../../widgets/receipt_lightbox_modal.dart';

class AddTransactionModal extends StatefulWidget {
  final Function(TransactionEntity) onSave;

  const AddTransactionModal({super.key, required this.onSave});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();

  String _type = 'debit';
  String _category = 'Food & Dining';
  String _platform = 'Google Pay';
  String? _receiptPath;

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt(ImageSource source) async {
    final receiptService = sl<ReceiptService>();
    final path = await receiptService.pickAndSaveReceipt(source: source);
    if (path != null && mounted) {
      setState(() {
        _receiptPath = path;
      });
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Attach Receipt / Bill Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.camera_alt_rounded, color: Colors.white),
                ),
                title: const Text('Take Photo with Camera'),
                subtitle: const Text('Snap paper bill or receipt slip'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickReceipt(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondary,
                  child: Icon(Icons.photo_library_rounded, color: Colors.white),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Upload bill photo or screenshot'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickReceipt(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    final txn = TransactionEntity(
      uid: const Uuid().v4(),
      amount: amount,
      type: _type,
      category: _category,
      merchant: _merchantController.text.trim().isNotEmpty
          ? _merchantController.text.trim()
          : null,
      platform: _platform,
      date: DateTime.now().millisecondsSinceEpoch,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      isAutomated: false,
      receiptPath: _receiptPath,
    );

    widget.onSave(txn);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('add_expense'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Type Toggle: Debit vs Credit
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Center(child: Text(context.tr('expense'))),
                    selected: _type == 'debit',
                    selectedColor: AppColors.debitRed.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: _type == 'debit' ? AppColors.debitRed : AppColors.textSecondaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _type = 'debit');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: Center(child: Text(context.tr('income'))),
                    selected: _type == 'credit',
                    selectedColor: AppColors.creditGreen.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: _type == 'credit' ? AppColors.creditGreen : AppColors.textSecondaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _type = 'credit');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                prefixText: '₹ ',
                hintText: '0.00',
              ),
            ),
            const SizedBox(height: 16),

            // Merchant Input
            TextField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant / Payee / Source',
                hintText: 'e.g. Swiggy, Amazon, Salary',
              ),
            ),
            const SizedBox(height: 16),

            // Category Selector Dropdown
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: AppConstants.getAllCategories().map((c) {
                return DropdownMenuItem<String>(
                  value: c['name'] as String,
                  child: Row(
                    children: [
                      Icon(c['icon'] as IconData, color: c['color'] as Color, size: 18),
                      const SizedBox(width: 10),
                      Text(c['name'] as String),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 16),

            // Platform Selector Dropdown
            DropdownButtonFormField<String>(
              initialValue: _platform,
              decoration: const InputDecoration(labelText: 'Payment Platform'),
              items: AppConstants.supportedPlatforms.map((p) {
                return DropdownMenuItem<String>(
                  value: p,
                  child: Text(p),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _platform = val);
              },
            ),
            const SizedBox(height: 16),

            // Notes Input
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Dinner with team, groceries, etc.',
              ),
            ),
            const SizedBox(height: 18),

            // Receipt Attachment Section
            const Text(
              'Bill / Receipt Photo',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            if (_receiptPath != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        ReceiptLightboxModal.show(
                          context: context,
                          receiptPath: _receiptPath!,
                          title: _merchantController.text.trim().isNotEmpty
                              ? _merchantController.text.trim()
                              : 'Attached Receipt',
                          onDelete: () {
                            setState(() => _receiptPath = null);
                          },
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(_receiptPath!),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ReceiptLightboxModal.show(
                            context: context,
                            receiptPath: _receiptPath!,
                            title: _merchantController.text.trim().isNotEmpty
                                ? _merchantController.text.trim()
                                : 'Attached Receipt',
                            onDelete: () {
                              setState(() => _receiptPath = null);
                            },
                          );
                        },
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Receipt Attached 📎',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Tap to preview or pinch-to-zoom',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.debitRed, size: 20),
                      tooltip: 'Remove',
                      onPressed: () {
                        setState(() => _receiptPath = null);
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showAttachmentOptions,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Attach Bill / Receipt Photo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: Text(context.tr('save')),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}
}
