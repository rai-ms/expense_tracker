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
  final _txnIdController = TextEditingController();
  final _platformController = TextEditingController();
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
    _txnIdController.dispose();
    _platformController.dispose();
    super.dispose();
  }

  void _submit() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    final txnId = _txnIdController.text.trim();
    final platform = _platformController.text.trim();

    final entry = KhataEntryEntity(
      uid: const Uuid().v4(),
      amount: amount,
      type: _type,
      date: DateTime.now().millisecondsSinceEpoch,
      dueDate: _dueDate?.millisecondsSinceEpoch,
      transactionId: txnId.isNotEmpty ? txnId : null,
      platform: platform.isNotEmpty ? platform : null,
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
          const SizedBox(height: 14),

          // Notes Field
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes / Reason',
              prefixIcon: Icon(Icons.note_alt_outlined),
              hintText: 'e.g. Lunch split, movie ticket, loan',
            ),
          ),
          const SizedBox(height: 14),

          // Optional Transaction ID & Platform Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _txnIdController,
                  decoration: const InputDecoration(
                    labelText: 'Txn ID / UTR (optional)',
                    prefixIcon: Icon(Icons.tag_rounded),
                    hintText: 'e.g. 4291848194',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _platformController,
                  decoration: const InputDecoration(
                    labelText: 'Mode / App',
                    hintText: 'e.g. UPI, GPay',
                  ),
                ),
              ),
            ],
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
        ),
      ),
    );
  }
}
