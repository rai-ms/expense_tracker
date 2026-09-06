import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/services/event_bus/app_events.dart';

class ManageCategoriesModal extends StatefulWidget {
  final VoidCallback? onCategoriesChanged;

  const ManageCategoriesModal({
    super.key,
    this.onCategoriesChanged,
  });

  static Future<void> show({
    required BuildContext context,
    VoidCallback? onCategoriesChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManageCategoriesModal(onCategoriesChanged: onCategoriesChanged),
    );
  }

  @override
  State<ManageCategoriesModal> createState() => _ManageCategoriesModalState();
}

class _ManageCategoriesModalState extends State<ManageCategoriesModal> {
  late List<Map<String, dynamic>> _allCategories;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _allCategories = AppConstants.getAllCategories();
    });
  }

  List<Map<String, dynamic>> get _customCategories =>
      _allCategories.where((c) => c['isCustom'] == true).toList();

  List<Map<String, dynamic>> get _standardCategories =>
      _allCategories.where((c) => c['isCustom'] != true).toList();

  void _openAddOrEditCategoryDialog([Map<String, dynamic>? existing]) {
    final isEdit = existing != null;
    final nameController = TextEditingController(text: existing != null ? existing['name'] as String : '');
    Color selectedColor = existing != null
        ? (existing['color'] as Color)
        : AppColors.primary;
    IconData selectedIcon = existing != null
        ? (existing['icon'] as IconData)
        : Icons.label_rounded;

    final availableColors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.creditGreen,
      AppColors.food,
      AppColors.shopping,
      AppColors.travel,
      AppColors.bills,
      AppColors.entertainment,
      AppColors.investment,
      AppColors.health,
      AppColors.debitRed,
      AppColors.warningAmber,
      const Color(0xFF0D9488), // Teal
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFD97706), // Amber
      const Color(0xFF0284C7), // Sky
    ];

    final availableIcons = [
      Icons.label_rounded,
      Icons.fitness_center_rounded,
      Icons.pets_rounded,
      Icons.sports_esports_rounded,
      Icons.local_cafe_rounded,
      Icons.fastfood_rounded,
      Icons.menu_book_rounded,
      Icons.headphones_rounded,
      Icons.celebration_rounded,
      Icons.card_giftcard_rounded,
      Icons.flight_takeoff_rounded,
      Icons.home_repair_service_rounded,
      Icons.home_rounded,
      Icons.apartment_rounded,
      Icons.cut_rounded,
      Icons.subscriptions_rounded,
      Icons.school_rounded,
      Icons.work_rounded,
      Icons.car_rental_rounded,
      Icons.child_care_rounded,
      Icons.park_rounded,
      Icons.laptop_mac_rounded,
      Icons.local_gas_station_rounded,
      Icons.wifi_rounded,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 16,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEdit ? 'Edit Custom Category' : 'New Custom Category',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Live Preview Chip
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selectedColor.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(selectedIcon, color: selectedColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              nameController.text.trim().isEmpty ? 'Category Name' : nameController.text.trim(),
                              style: TextStyle(
                                color: selectedColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name Input
                    TextField(
                      controller: nameController,
                      autofocus: !isEdit,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        hintText: 'e.g. Gym, Subscriptions, Pet Care',
                        prefixIcon: Icon(Icons.edit_outlined),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Color Picker
                    const Text(
                      'Choose Color',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableColors.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, index) {
                          final color = availableColors[index];
                          final isSelected = selectedColor.toARGB32() == color.toARGB32();
                          return InkWell(
                            onTap: () => setModalState(() => selectedColor = color),
                            borderRadius: BorderRadius.circular(21),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Icon Picker
                    const Text(
                      'Choose Icon',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 120,
                      child: GridView.builder(
                        scrollDirection: Axis.horizontal,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1,
                        ),
                        itemCount: availableIcons.length,
                        itemBuilder: (_, index) {
                          final icon = availableIcons[index];
                          final isSelected = selectedIcon.codePoint == icon.codePoint;
                          return InkWell(
                            onTap: () => setModalState(() => selectedIcon = icon),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? selectedColor.withValues(alpha: 0.2)
                                    : (isDark ? AppColors.darkSurface : AppColors.lightSurfaceVariant),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? selectedColor : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? selectedColor : AppColors.textSecondaryDark,
                                size: 22,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: nameController.text.trim().isEmpty
                            ? null
                            : () {
                                final name = nameController.text.trim();
                                if (isEdit) {
                                  AppConstants.updateCustomCategory(
                                    oldName: existing['name'] as String,
                                    newName: name,
                                    icon: selectedIcon,
                                    color: selectedColor,
                                  );
                                } else {
                                  AppConstants.addCustomCategory(
                                    name: name,
                                    icon: selectedIcon,
                                    color: selectedColor,
                                  );
                                }
                                AppEvents.notifyDataChanged();
                                Navigator.pop(context);
                                _loadCategories();
                                widget.onCategoriesChanged?.call();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          isEdit ? 'Save Changes' : 'Create Category',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCategory(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "$name"? Transactions with this category will retain their category name.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              AppConstants.deleteCustomCategory(name);
              AppEvents.notifyDataChanged();
              Navigator.pop(ctx);
              _loadCategories();
              widget.onCategoriesChanged?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.debitRed),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final customList = _customCategories;
    final standardList = _standardCategories;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Categories',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Create and customize transaction categories',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiaryDark),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Add New Category Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: InkWell(
              onTap: () => _openAddOrEditCategoryDialog(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '+ Add New Custom Category',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Category Lists
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Custom Categories Section
                Row(
                  children: [
                    const Text(
                      'Custom Categories',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${customList.length}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (customList.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.category_outlined, size: 36, color: AppColors.textTertiaryDark),
                          SizedBox(height: 8),
                          Text(
                            'No custom categories created yet',
                            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...customList.map((cat) {
                    final name = cat['name'] as String;
                    final icon = cat['icon'] as IconData;
                    final color = cat['color'] as Color;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edit',
                            onPressed: () => _openAddOrEditCategoryDialog(cat),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.debitRed),
                            tooltip: 'Delete',
                            onPressed: () => _confirmDeleteCategory(name),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 16),

                // Standard Categories Section
                Row(
                  children: [
                    const Text(
                      'Standard Categories',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.textTertiaryDark.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${standardList.length}',
                        style: const TextStyle(
                          color: AppColors.textTertiaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ...standardList.map((cat) {
                  final name = cat['name'] as String;
                  final icon = cat['icon'] as IconData;
                  final color = cat['color'] as Color;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: (theme.cardTheme.color ?? (isDark ? AppColors.darkCard : AppColors.lightCard))
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder.withValues(alpha: 0.4)
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Built-in',
                            style: TextStyle(fontSize: 10, color: AppColors.textTertiaryDark),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
