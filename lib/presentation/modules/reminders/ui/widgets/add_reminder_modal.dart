import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../data/models/bill_reminder_entity.dart';

class AddReminderModal extends StatefulWidget {
  final Function(BillReminderEntity) onSave;

  const AddReminderModal({super.key, required this.onSave});

  @override
  State<AddReminderModal> createState() => _AddReminderModalState();
}

class _AddReminderModalState extends State<AddReminderModal> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));
  String _category = 'Bills & Utilities';
  String _recurrence = 'monthly';

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();
    if (title.isEmpty || amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    final reminder = BillReminderEntity(
      uid: const Uuid().v4(),
      title: title,
      amount: amount,
      dueDate: _dueDate.millisecondsSinceEpoch,
      category: _category,
      recurrence: _recurrence,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      isPaid: false,
    );

    widget.onSave(reminder);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy');

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
                  'Add Bill Reminder',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Bill / Reminder Name *',
                hintText: 'e.g. HDFC Credit Card, Electricity, Wi-Fi',
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Estimated Amount (₹) *',
                prefixText: '₹ ',
                hintText: '0.00',
              ),
            ),
            const SizedBox(height: 16),

            // Due Date Picker Tile
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Due Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text(
                dateFormat.format(_dueDate),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.calendar_month_rounded),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _dueDate = picked);
                }
              },
            ),
            const SizedBox(height: 16),

            // Recurrence
            DropdownButtonFormField<String>(
              initialValue: _recurrence,
              decoration: const InputDecoration(labelText: 'Repeat Frequency'),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('Once (No repeat)')),
                DropdownMenuItem(value: 'weekly', child: Text('Every Week')),
                DropdownMenuItem(value: 'monthly', child: Text('Every Month')),
                DropdownMenuItem(value: 'yearly', child: Text('Every Year')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _recurrence = val);
              },
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: AppConstants.categories.map((c) {
                return DropdownMenuItem<String>(
                  value: c['name'] as String,
                  child: Text(c['name'] as String),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Reminder'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
