import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/khata_contact_entity.dart';
import '../../../../../data/models/khata_entry_entity.dart';

class AddEntryModal extends StatefulWidget {
  final KhataContactEntity contact;
  final Function(KhataEntryEntity) onSave;
  final String initialType;

  const AddEntryModal({
    super.key,
    required this.contact,
    required this.onSave,
    this.initialType = 'gave',
  });

  @override
  State<AddEntryModal> createState() => _AddEntryModalState();
}

class _AddEntryModalState extends State<AddEntryModal> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  late String _type;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    final entry = KhataEntryEntity(
      uid: const Uuid().v4(),
      amount: amount,
      type: _type,
      date: DateTime.now().millisecondsSinceEpoch,
      dueDate: _dueDate?.millisecondsSinceEpoch,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      isSettled: false,
    );

    widget.onSave(entry);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Entry for ${widget.contact.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Gave vs Got Toggle
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Maine Diye (Gave)')),
                  selected: _type == 'gave',
                  selectedColor: AppColors.debitRed.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _type == 'gave' ? AppColors.debitRed : AppColors.textSecondaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _type = 'gave');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Mujhe Mile (Got)')),
                  selected: _type == 'got',
                  selectedColor: AppColors.creditGreen.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _type == 'got' ? AppColors.creditGreen : AppColors.textSecondaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _type = 'got');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount Field
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

          // Notes Field
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes / Reason',
              hintText: 'e.g. Lunch split, movie ticket, loan',
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _type == 'gave' ? AppColors.debitRed : AppColors.creditGreen,
              ),
              child: Text(
                _type == 'gave' ? 'Save "Maine Diye"' : 'Save "Mujhe Mile"',
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
