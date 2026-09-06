import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../data/models/khata_contact_entity.dart';

class AddContactModal extends StatefulWidget {
  final Function(KhataContactEntity) onSave;

  const AddContactModal({super.key, required this.onSave});

  @override
  State<AddContactModal> createState() => _AddContactModalState();
}

class _AddContactModalState extends State<AddContactModal> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final List<int> _colors = [
    0xFF6366F1, 0xFF10B981, 0xFFEF4444, 0xFFF59E0B,
    0xFF8B5CF6, 0xFFEC4899, 0xFF06B6D4, 0xFF3B82F6,
  ];
  int _selectedColor = 0xFF6366F1;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final contact = KhataContactEntity(
      uid: const Uuid().v4(),
      name: name,
      phoneNumber: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      avatarColorValue: _selectedColor,
    );

    widget.onSave(contact);
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
                context.tr('add_customer'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: '${context.tr('add_customer')} *',
              hintText: 'e.g. Rahul Sharma, Amit Verma',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number (${context.tr('whatsapp_reminder')})',
              hintText: 'e.g. 9876543210',
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Avatar Color',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            children: _colors.map((c) {
              final isSelected = c == _selectedColor;
              return InkWell(
                onTap: () => setState(() => _selectedColor = c),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
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
