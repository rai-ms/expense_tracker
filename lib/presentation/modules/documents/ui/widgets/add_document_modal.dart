import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/document_entity.dart';
import '../../bloc/document_category.dart';

typedef OnDocumentSave = void Function({
  required String name,
  required String category,
  required String sourcePath,
  String? notes,
});

typedef OnDocumentUpdate = void Function({
  required int id,
  required String name,
  required String category,
  String? notes,
});

class AddDocumentModal extends StatefulWidget {
  final OnDocumentSave? onSave;
  final OnDocumentUpdate? onUpdate;
  final DocumentEntity? existingDocument;
  final String? initialName;
  final String? initialPath;

  const AddDocumentModal({
    super.key,
    this.onSave,
    this.onUpdate,
    this.existingDocument,
    this.initialName,
    this.initialPath,
  });

  @override
  State<AddDocumentModal> createState() => _AddDocumentModalState();
}

class _AddDocumentModalState extends State<AddDocumentModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;

  String _selectedCategory = 'Salary';
  String? _pickedFilePath;
  String? _pickedFileName;
  bool _isSaving = false;

  bool get _isEditMode => widget.existingDocument != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final doc = widget.existingDocument!;
      _nameCtrl = TextEditingController(text: doc.name);
      _notesCtrl = TextEditingController(text: doc.notes ?? '');
      _selectedCategory = doc.category;
      _pickedFilePath = doc.filePath;
      _pickedFileName = p.basename(doc.filePath);
    } else {
      _nameCtrl = TextEditingController(text: widget.initialName ?? '');
      _notesCtrl = TextEditingController();
      _pickedFilePath = widget.initialPath;
      if (widget.initialPath != null) {
        _pickedFileName = p.basename(widget.initialPath!);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (_isEditMode) return; // In edit mode, original vault file is retained
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result.isNotEmpty && result.single.path != null) {
      final path = result.single.path!;
      final name = result.single.name;
      setState(() {
        _pickedFilePath = path;
        _pickedFileName = name;
        if (_nameCtrl.text.trim().isEmpty) {
          _nameCtrl.text = name.replaceAll(RegExp(r'\.[^.]+$'), '');
        }
      });
    }
  }

  void _submit() {
    if (_pickedFilePath == null && !_isEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a file first')),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    final notesText = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

    if (_isEditMode) {
      widget.onUpdate?.call(
        id: widget.existingDocument!.id,
        name: _nameCtrl.text.trim(),
        category: _selectedCategory,
        notes: notesText,
      );
    } else {
      widget.onSave?.call(
        name: _nameCtrl.text.trim(),
        category: _selectedCategory,
        sourcePath: _pickedFilePath!,
        notes: notesText,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 8,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.darkBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                _isEditMode ? 'Edit Document' : 'Add Document',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _isEditMode
                    ? 'Update notes, title, or category'
                    : 'Salary slips, insurance, tax forms — all in one place',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),

              // File Picker Card
              GestureDetector(
                onTap: _pickFile,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _pickedFilePath != null
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : (isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _pickedFilePath != null
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.darkBorder.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _pickedFilePath != null
                              ? Icons.description_rounded
                              : Icons.upload_file_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pickedFilePath != null
                                  ? _pickedFileName ?? 'File selected'
                                  : 'Tap to pick file',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: _pickedFilePath != null
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'PDF, JPG, PNG supported',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_pickedFilePath != null)
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.creditGreen, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Document Name
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Document Name',
                  hintText: 'e.g. June 2025 Salary Slip',
                  prefixIcon: const Icon(Icons.label_outline_rounded),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  filled: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Category
              Text(
                'Category',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DocumentCategory.all
                    .where((c) => c != 'All')
                    .map((cat) {
                  final meta = DocumentCategory.get(cat);
                  final isSelected = _selectedCategory == cat;
                  final catColor = meta['color'] as Color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? catColor.withValues(alpha: 0.15)
                            : (isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.lightSurfaceVariant),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? catColor
                              : AppColors.darkBorder.withValues(alpha: 0.4),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            meta['icon'] as IconData,
                            size: 14,
                            color:
                                isSelected ? catColor : AppColors.textTertiaryDark,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? catColor
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'e.g. FY 2024-25, HDFC Bank',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  filled: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Save button with Bottom SafeArea
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : (_isEditMode ? 'Save Changes' : 'Save Document'),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
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
