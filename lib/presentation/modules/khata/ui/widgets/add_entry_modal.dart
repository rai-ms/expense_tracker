import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/services/di/injection.dart';
import '../../../../../core/services/receipt_service/receipt_service.dart';
import '../../../../../data/models/khata_contact_entity.dart';
import '../../../../../data/models/khata_entry_entity.dart';
import '../../../../widgets/receipt_lightbox_modal.dart';

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
  String? _receiptPath;

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
                'Attach Bill or Payment Screenshot',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.camera_alt_rounded, color: Colors.white),
                ),
                title: const Text('Take Photo with Camera'),
                subtitle: const Text('Snap receipt or handwritten slip'),
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
                subtitle: const Text('Pick UPI screenshot or bill image'),
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
      receiptPath: _receiptPath,
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
                '${context.tr('khata')}: ${widget.contact.name}',
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
              const SizedBox(width: 12),
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
          const SizedBox(height: 16),

          // Bill / Receipt Attachment
          const Text(
            'Bill / Payment Proof (Optional)',
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
                        title: '${widget.contact.name} Entry Receipt',
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
                          title: '${widget.contact.name} Entry Receipt',
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
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _showAttachmentOptions,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.darkBorder, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.darkSurfaceVariant.withValues(alpha: 0.2),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.attach_file_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Attach Bill / UPI Receipt Photo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
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
              style: ElevatedButton.styleFrom(
                backgroundColor: _type == 'gave' ? AppColors.debitRed : AppColors.creditGreen,
              ),
              child: Text(
                context.tr('save'),
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
