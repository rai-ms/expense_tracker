import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/services/di/injection.dart';
import '../../../../../core/services/event_bus/app_events.dart';
import '../../../../../data/models/khata_contact_entity.dart';
import '../../../../../data/models/khata_entry_entity.dart';
import '../../../../../data/models/transaction_entity.dart';
import '../../../../../domain/repositories/i_khata_repository.dart';

class MoveToKhataModal extends StatefulWidget {
  final TransactionEntity transaction;

  const MoveToKhataModal({
    super.key,
    required this.transaction,
  });

  @override
  State<MoveToKhataModal> createState() => _MoveToKhataModalState();
}

class _MoveToKhataModalState extends State<MoveToKhataModal> {
  late final IKhataRepository _khataRepo;
  List<KhataContactEntity> _contacts = [];
  KhataContactEntity? _selectedContact;

  final _newContactController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountController = TextEditingController();
  late String _type; // 'gave' or 'got'
  bool _isCreatingNew = false;

  @override
  void initState() {
    super.initState();
    _khataRepo = sl<IKhataRepository>();
    _contacts = _khataRepo.getAllContacts();

    _amountController.text = widget.transaction.amount.toStringAsFixed(0);
    _type = widget.transaction.isDebit ? 'gave' : 'got';
    _notesController.text = widget.transaction.merchant ??
        widget.transaction.notes ??
        widget.transaction.category;

    if (_contacts.isNotEmpty) {
      _selectedContact = _contacts.first;
    } else {
      _isCreatingNew = true;
    }
  }

  @override
  void dispose() {
    _newContactController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    KhataContactEntity targetContact;

    if (_isCreatingNew || _selectedContact == null) {
      final name = _newContactController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter contact name')),
        );
        return;
      }

      final newContact = KhataContactEntity(
        uid: const Uuid().v4(),
        name: name,
        avatarColorValue: AppColors.primary.toARGB32(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final contactId = _khataRepo.addContact(newContact);
      targetContact = _khataRepo.getContactById(contactId)!;
    } else {
      targetContact = _selectedContact!;
    }

    final entry = KhataEntryEntity(
      uid: const Uuid().v4(),
      amount: amount,
      type: _type,
      date: widget.transaction.date,
      transactionId: widget.transaction.transactionId,
      platform: widget.transaction.platform,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      isSettled: false,
    );

    _khataRepo.addEntry(targetContact.id, entry);
    AppEvents.notifyDataChanged();

    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Moved to KhataBook: ${_type == 'gave' ? 'You Gave' : 'You Got'} ₹${amount.toStringAsFixed(0)} with ${targetContact.name}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, color: AppColors.khataBook, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('khata'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Linked Transaction Metadata Pill
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.transaction.merchant ?? widget.transaction.category,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.transaction.transactionId != null
                                ? 'Txn ID: ${widget.transaction.transactionId!} • ${widget.transaction.platform ?? "UPI"}'
                                : 'Platform: ${widget.transaction.platform ?? "Bank/SMS"}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Linked',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Mode switcher: Existing vs New Contact
              if (_contacts.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: const Center(child: Text('Existing Contact')),
                        selected: !_isCreatingNew,
                        onSelected: (val) {
                          if (val) setState(() => _isCreatingNew = false);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Center(child: Text('+ New Contact')),
                        selected: _isCreatingNew,
                        onSelected: (val) {
                          if (val) setState(() => _isCreatingNew = true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              if (!_isCreatingNew && _contacts.isNotEmpty) ...[
                const Text(
                  'Select Khata Contact',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<KhataContactEntity>(
                  initialValue: _selectedContact,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  items: _contacts.map((contact) {
                    return DropdownMenuItem(
                      value: contact,
                      child: Text(
                        '${contact.name} (${currency.format(contact.netBalance)})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedContact = val);
                  },
                ),
              ] else ...[
                TextField(
                  controller: _newContactController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Contact Name (Person / Business)',
                    prefixIcon: Icon(Icons.person_add_alt_1_rounded),
                    hintText: 'e.g. Rahul Sharma, Kirana Store',
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Entry Type: Gave vs Got
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text(context.tr('you_gave'))),
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text(context.tr('you_got'))),
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
              const SizedBox(height: 14),

              // Amount & Notes
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Remark / Notes',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(context.tr('save')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type == 'gave' ? AppColors.debitRed : AppColors.creditGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
