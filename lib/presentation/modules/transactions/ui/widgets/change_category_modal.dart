import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/services/di/injection.dart';
import '../../../../../core/services/event_bus/app_events.dart';
import '../../../../../core/services/objectbox_service/objectbox_service.dart';
import '../../../../../data/models/transaction_entity.dart';
import '../../../../../domain/repositories/i_transaction_repository.dart';

class ChangeCategoryModal extends StatefulWidget {
  final TransactionEntity transaction;

  const ChangeCategoryModal({
    super.key,
    required this.transaction,
  });

  static Future<void> show({
    required BuildContext context,
    required TransactionEntity transaction,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeCategoryModal(transaction: transaction),
    );
  }

  @override
  State<ChangeCategoryModal> createState() => _ChangeCategoryModalState();
}

class _ChangeCategoryModalState extends State<ChangeCategoryModal> {
  static const String _prefCustomCategoriesKey = 'user_custom_categories_list';
  late String _selectedCategory;
  final List<String> _customCategories = [];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.transaction.category;
    _loadCustomCategories();
  }

  void _loadCustomCategories() {
    final list = ObjectBoxService.instance.getStringListSetting(_prefCustomCategoriesKey);
    setState(() {
      _customCategories.clear();
      _customCategories.addAll(list);
    });
  }

  void _addCustomCategoryDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryLight),
            SizedBox(width: 10),
            Text('New Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'e.g. Gym, Pet Care, Subscription',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                final list = ObjectBoxService.instance.getStringListSetting(_prefCustomCategoriesKey);
                if (!list.contains(name)) {
                  list.add(name);
                  ObjectBoxService.instance.setStringListSetting(_prefCustomCategoriesKey, list);
                }
                Navigator.pop(ctx);
                _loadCustomCategories();
                setState(() {
                  _selectedCategory = name;
                });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }

  void _applyCategory(String category) {
    HapticFeedback.selectionClick();
    final repo = sl<ITransactionRepository>();
    widget.transaction.category = category;
    repo.updateTransaction(widget.transaction);
    AppEvents.notifyDataChanged();

    Navigator.pop(context); // Close category modal
    Navigator.pop(context); // Close detail modal so views refresh cleanly

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category updated to "$category"'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Built-in categories
    final defaultCategories = AppConstants.categories;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.category_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Category',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Select or create a new category',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _addCustomCategoryDialog,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryLight,
                  side: const BorderSide(color: AppColors.primaryLight),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Category Grid
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Standard Categories Grid
                  const Text(
                    'Standard Categories',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.8,
                    ),
                    itemCount: defaultCategories.length,
                    itemBuilder: (context, index) {
                      final cat = defaultCategories[index];
                      final catName = cat['name'] as String;
                      final catColor = cat['color'] as Color;
                      final catIcon = cat['icon'] as IconData;
                      final isSelected = _selectedCategory.toLowerCase() == catName.toLowerCase();

                      return InkWell(
                        onTap: () => _applyCategory(catName),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? catColor.withValues(alpha: 0.2)
                                : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? catColor
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(catIcon, color: catColor, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  catName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded, color: catColor, size: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Custom User-Created Categories (if any)
                  if (_customCategories.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Your Custom Categories',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _customCategories.map((customName) {
                        final isSelected = _selectedCategory.toLowerCase() == customName.toLowerCase();
                        return InkWell(
                          onTap: () => _applyCategory(customName),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryLight : AppColors.darkBorder,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.label_rounded, color: AppColors.primaryLight, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  customName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? AppColors.primaryLight : null,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.check_rounded, color: AppColors.primaryLight, size: 16),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
