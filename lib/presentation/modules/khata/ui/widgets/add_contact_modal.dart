import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/constants/app_colors.dart';
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
  final FlutterNativeContactPicker _contactPicker = FlutterNativeContactPicker();

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

  Future<void> _pickContactFromPhone() async {
    try {
      final Contact? contact = await _contactPicker.selectContact();
      if (contact != null) {
        if (contact.fullName != null && contact.fullName!.trim().isNotEmpty) {
          _nameController.text = contact.fullName!.trim();
        }
        final phone = contact.selectedPhoneNumber ??
            (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty
                ? contact.phoneNumbers!.first
                : null);
        if (phone != null && phone.isNotEmpty) {
          _phoneController.text = phone.replaceAll(RegExp(r'[^\d+]'), '');
        }
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error picking contact: $e');
    }
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
              const SizedBox(height: 12),

              // Quick Contact Picker Action Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickContactFromPhone,
                  icon: const Icon(Icons.contacts_rounded, size: 18, color: AppColors.primary),
                  label: Text(
                    context.tr('pick_contact'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '${context.tr('add_customer')} *',
                  hintText: 'e.g. Rahul Sharma, Amit Verma',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number (${context.tr('whatsapp_reminder')})',
                  hintText: 'e.g. 9876543210',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.contact_phone_outlined, color: AppColors.primary),
                    tooltip: context.tr('pick_contact'),
                    onPressed: _pickContactFromPhone,
                  ),
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
