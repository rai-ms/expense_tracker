import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../data/models/transaction_entity.dart';

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

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
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
    );

    widget.onSave(txn);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
                const Text(
                  'Add New Transaction',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    label: const Center(child: Text('Expense (Debit)')),
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
                    label: const Center(child: Text('Income (Credit)')),
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
              items: AppConstants.categories.map((c) {
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
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Transaction'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
