import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/services/filter_service/saved_filter_service.dart';
import '../../models/saved_filter_preset.dart';
import '../../models/transaction_filter_criteria.dart';
import 'manage_categories_modal.dart';

class TransactionFilterModal extends StatefulWidget {
  final TransactionFilterCriteria initialCriteria;
  final List<String> availableCategories;
  final List<String> availablePlatforms;
  final ValueChanged<TransactionFilterCriteria> onApply;
  final VoidCallback? onClear;

  const TransactionFilterModal({
    super.key,
    required this.initialCriteria,
    required this.availableCategories,
    required this.availablePlatforms,
    required this.onApply,
    this.onClear,
  });

  @override
  State<TransactionFilterModal> createState() => _TransactionFilterModalState();
}

enum _FilterTab {
  saved,
  date,
  type,
  category,
  platform,
  amount,
  sort,
}

class _TransactionFilterModalState extends State<TransactionFilterModal> {
  _FilterTab _selectedTab = _FilterTab.date;

  late TransactionDateFilter _dateFilter;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  late Set<String> _types;
  late Set<String> _categories;
  late Set<String> _platforms;
  double? _minAmount;
  double? _maxAmount;
  late TransactionSortBy _sortBy;

  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  final TextEditingController _categorySearchController = TextEditingController();
  String _categorySearchQuery = '';

  List<SavedFilterPreset> _savedPresets = [];

  @override
  void initState() {
    super.initState();
    _dateFilter = widget.initialCriteria.dateFilter;
    _customStartDate = widget.initialCriteria.customStartDate;
    _customEndDate = widget.initialCriteria.customEndDate;
    _types = Set<String>.from(widget.initialCriteria.types);
    _categories = Set<String>.from(widget.initialCriteria.categories);
    _platforms = Set<String>.from(widget.initialCriteria.platforms);
    _minAmount = widget.initialCriteria.minAmount;
    _maxAmount = widget.initialCriteria.maxAmount;
    _sortBy = widget.initialCriteria.sortBy;

    if (_minAmount != null) {
      _minAmountController.text = _minAmount!.toInt().toString();
    }
    if (_maxAmount != null) {
      _maxAmountController.text = _maxAmount!.toInt().toString();
    }

    _loadSavedPresets();
  }

  void _loadSavedPresets() {
    setState(() {
      _savedPresets = SavedFilterService.getSavedFilters();
    });
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _categorySearchController.dispose();
    super.dispose();
  }

  int get _activeCount {
    int count = 0;
    if (_dateFilter != TransactionDateFilter.thisMonth) count++;
    if (_types.isNotEmpty) count += _types.length;
    if (_categories.isNotEmpty) count += _categories.length;
    if (_platforms.isNotEmpty) count += _platforms.length;
    if (_minAmount != null || _maxAmount != null) count++;
    if (_sortBy != TransactionSortBy.dateNewest) count++;
    return count;
  }

  int _getTabCount(_FilterTab tab) {
    switch (tab) {
      case _FilterTab.saved:
        return _savedPresets.length;
      case _FilterTab.date:
        return _dateFilter != TransactionDateFilter.thisMonth ? 1 : 0;
      case _FilterTab.type:
        return _types.length;
      case _FilterTab.category:
        return _categories.length;
      case _FilterTab.platform:
        return _platforms.length;
      case _FilterTab.amount:
        return (_minAmount != null || _maxAmount != null) ? 1 : 0;
      case _FilterTab.sort:
        return _sortBy != TransactionSortBy.dateNewest ? 1 : 0;
    }
  }

  void _resetAll() {
    setState(() {
      _dateFilter = TransactionDateFilter.thisMonth;
      _customStartDate = null;
      _customEndDate = null;
      _types.clear();
      _categories.clear();
      _platforms.clear();
      _minAmount = null;
      _maxAmount = null;
      _sortBy = TransactionSortBy.dateNewest;
      _minAmountController.clear();
      _maxAmountController.clear();
      _categorySearchController.clear();
      _categorySearchQuery = '';
    });
    widget.onClear?.call();
  }

  TransactionFilterCriteria _buildCurrentCriteria() {
    final min = double.tryParse(_minAmountController.text.trim());
    final max = double.tryParse(_maxAmountController.text.trim());

    return TransactionFilterCriteria(
      dateFilter: _dateFilter,
      customStartDate: _customStartDate,
      customEndDate: _customEndDate,
      types: _types,
      categories: _categories,
      platforms: _platforms,
      minAmount: min,
      maxAmount: max,
      sortBy: _sortBy,
      searchQuery: widget.initialCriteria.searchQuery,
    );
  }

  void _apply() {
    final criteria = _buildCurrentCriteria();
    widget.onApply(criteria);
    Navigator.of(context).pop();
  }

  void _applyPreset(SavedFilterPreset preset) {
    setState(() {
      _dateFilter = preset.criteria.dateFilter;
      _customStartDate = preset.criteria.customStartDate;
      _customEndDate = preset.criteria.customEndDate;
      _types = Set<String>.from(preset.criteria.types);
      _categories = Set<String>.from(preset.criteria.categories);
      _platforms = Set<String>.from(preset.criteria.platforms);
      _minAmount = preset.criteria.minAmount;
      _maxAmount = preset.criteria.maxAmount;
      _sortBy = preset.criteria.sortBy;

      _minAmountController.text = _minAmount?.toInt().toString() ?? '';
      _maxAmountController.text = _maxAmount?.toInt().toString() ?? '';
    });
    widget.onApply(_buildCurrentCriteria());
    Navigator.of(context).pop();
  }

  void _showSavePresetDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.bookmark_add_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Save Filter Preset'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Give this filter combination a name for quick 1-tap access anytime:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Filter Name',
                  hintText: 'e.g. Monthly Dining, High GPay Spends',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final preset = SavedFilterPreset(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  criteria: _buildCurrentCriteria(),
                  createdAt: DateTime.now(),
                );

                SavedFilterService.saveFilter(preset);
                Navigator.pop(ctx);
                _loadSavedPresets();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Filter "$name" saved successfully!'),
                    backgroundColor: AppColors.creditGreen,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Preset'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.82,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle pill
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
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_activeCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_activeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // Save Filter Action
                IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined, color: AppColors.primary),
                  tooltip: 'Save Filter as Preset',
                  visualDensity: VisualDensity.compact,
                  onPressed: _showSavePresetDialog,
                ),
                if (_activeCount > 0)
                  TextButton(
                    onPressed: _resetAll,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.debitRed,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Body: Two Column E-commerce layout
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Filter Categories (Tabs)
                Container(
                  width: 125,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface.withValues(alpha: 0.5)
                        : AppColors.lightSurfaceVariant.withValues(alpha: 0.6),
                    border: Border(
                      right: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                  ),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildTabItem(
                        _FilterTab.saved,
                        'Saved',
                        Icons.bookmark_rounded,
                        isAccent: true,
                      ),
                      _buildTabItem(_FilterTab.date, 'Date Range', Icons.calendar_month_outlined),
                      _buildTabItem(_FilterTab.type, 'Type', Icons.swap_horiz_rounded),
                      _buildTabItem(_FilterTab.category, 'Category', Icons.category_outlined),
                      _buildTabItem(_FilterTab.platform, 'Bank / App', Icons.account_balance_outlined),
                      _buildTabItem(_FilterTab.amount, 'Amount', Icons.currency_rupee_rounded),
                      _buildTabItem(_FilterTab.sort, 'Sort By', Icons.sort_rounded),
                    ],
                  ),
                ),

                // Right Column: Filter Options
                Expanded(
                  child: Container(
                    color: theme.scaffoldBackgroundColor,
                    child: _buildTabContent(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetAll,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _apply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _activeCount > 0 ? 'Apply Filters ($_activeCount)' : 'Apply Filters',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    _FilterTab tab,
    String title,
    IconData icon, {
    bool isAccent = false,
  }) {
    final isSelected = _selectedTab == tab;
    final count = _getTabCount(tab);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? theme.scaffoldBackgroundColor : theme.cardTheme.color)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 3.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.primary
                      : isAccent
                          ? AppColors.warningAmber
                          : AppColors.textSecondaryDark,
                ),
                const Spacer(),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isAccent ? AppColors.warningAmber : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                    : isAccent
                        ? AppColors.warningAmber
                        : AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case _FilterTab.saved:
        return _buildSavedFiltersTab();
      case _FilterTab.date:
        return _buildDateTab();
      case _FilterTab.type:
        return _buildTypeTab();
      case _FilterTab.category:
        return _buildCategoryTab();
      case _FilterTab.platform:
        return _buildPlatformTab();
      case _FilterTab.amount:
        return _buildAmountTab();
      case _FilterTab.sort:
        return _buildSortTab();
    }
  }

  // --- 0. Saved Filters Tab ---
  Widget _buildSavedFiltersTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Saved Filter Presets',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            TextButton.icon(
              onPressed: _showSavePresetDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Save Current'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        if (_savedPresets.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface.withValues(alpha: 0.5) : AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.bookmark_border_rounded, size: 38, color: AppColors.textTertiaryDark),
                const SizedBox(height: 10),
                const Text(
                  'No Saved Filters Yet',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Set your preferred filters across tabs and tap "+ Save Current" to create a quick preset.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiaryDark),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _showSavePresetDialog,
                  icon: const Icon(Icons.bookmark_add_rounded, size: 16),
                  label: const Text('Save Current Filter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          )
        else
          ..._savedPresets.map((preset) {
            final activeFiltersList = <String>[];
            if (preset.criteria.types.isNotEmpty) {
              activeFiltersList.addAll(preset.criteria.types);
            }
            if (preset.criteria.categories.isNotEmpty) {
              activeFiltersList.addAll(preset.criteria.categories);
            }
            if (preset.criteria.platforms.isNotEmpty) {
              activeFiltersList.addAll(preset.criteria.platforms);
            }
            if (preset.criteria.minAmount != null || preset.criteria.maxAmount != null) {
              activeFiltersList.add('₹ amount range');
            }

            final summaryText = activeFiltersList.isEmpty
                ? 'Standard filter'
                : activeFiltersList.take(3).join(' • ');

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.bookmark_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preset.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summaryText,
                          style: const TextStyle(fontSize: 11, color: AppColors.textTertiaryDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.debitRed),
                    tooltip: 'Delete Preset',
                    onPressed: () {
                      SavedFilterService.deleteFilter(preset.id);
                      _loadSavedPresets();
                    },
                  ),
                  ElevatedButton(
                    onPressed: () => _applyPreset(preset),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // --- 1. Date Range Tab ---
  Widget _buildDateTab() {
    final now = DateTime.now();
    final dateFormat = DateFormat('dd MMM yyyy');

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        const Text(
          'Select Time Period',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        _buildRadioOption<TransactionDateFilter>(
          title: 'This Month',
          subtitle: DateFormat('MMMM yyyy').format(now),
          value: TransactionDateFilter.thisMonth,
          groupValue: _dateFilter,
          onChanged: (val) => setState(() => _dateFilter = val!),
        ),
        _buildRadioOption<TransactionDateFilter>(
          title: 'Today',
          subtitle: dateFormat.format(now),
          value: TransactionDateFilter.today,
          groupValue: _dateFilter,
          onChanged: (val) => setState(() => _dateFilter = val!),
        ),
        _buildRadioOption<TransactionDateFilter>(
          title: 'This Week',
          subtitle: 'Current 7 days',
          value: TransactionDateFilter.thisWeek,
          groupValue: _dateFilter,
          onChanged: (val) => setState(() => _dateFilter = val!),
        ),
        _buildRadioOption<TransactionDateFilter>(
          title: 'Last Month',
          subtitle: DateFormat('MMMM yyyy').format(DateTime(now.year, now.month - 1, 1)),
          value: TransactionDateFilter.lastMonth,
          groupValue: _dateFilter,
          onChanged: (val) => setState(() => _dateFilter = val!),
        ),
        _buildRadioOption<TransactionDateFilter>(
          title: 'All Time',
          subtitle: 'All historical records',
          value: TransactionDateFilter.allTime,
          groupValue: _dateFilter,
          onChanged: (val) => setState(() => _dateFilter = val!),
        ),
        _buildRadioOption<TransactionDateFilter>(
          title: 'Custom Range',
          subtitle: (_customStartDate != null && _customEndDate != null)
              ? '${DateFormat('dd MMM').format(_customStartDate!)} - ${DateFormat('dd MMM').format(_customEndDate!)}'
              : 'Choose custom dates',
          value: TransactionDateFilter.custom,
          groupValue: _dateFilter,
          onChanged: (val) async {
            setState(() => _dateFilter = val!);
            await _pickCustomDateRange();
          },
          trailing: IconButton(
            icon: const Icon(Icons.date_range_rounded, size: 20, color: AppColors.primary),
            onPressed: _pickCustomDateRange,
          ),
        ),
      ],
    );
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 30)),
      initialDateRange: DateTimeRange(
        start: _customStartDate ?? DateTime(now.year, now.month, 1),
        end: _customEndDate ?? now,
      ),
    );

    if (picked != null) {
      setState(() {
        _dateFilter = TransactionDateFilter.custom;
        _customStartDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _customEndDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
    }
  }

  // --- 2. Type Tab (Multi-Select) ---
  Widget _buildTypeTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        const Text(
          'Transaction Types (Multi-select)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select one or more types to filter',
          style: TextStyle(fontSize: 12, color: AppColors.textTertiaryDark),
        ),
        const SizedBox(height: 12),
        _buildCheckboxOption(
          title: 'Expense / Debit',
          subtitle: 'Money going out (💸)',
          icon: Icons.arrow_upward_rounded,
          iconColor: AppColors.debitRed,
          isSelected: _types.contains('debit'),
          onChanged: (val) {
            setState(() {
              if (val == true) {
                _types.add('debit');
              } else {
                _types.remove('debit');
              }
            });
          },
        ),
        _buildCheckboxOption(
          title: 'Income / Credit',
          subtitle: 'Money coming in (💰)',
          icon: Icons.arrow_downward_rounded,
          iconColor: AppColors.creditGreen,
          isSelected: _types.contains('credit'),
          onChanged: (val) {
            setState(() {
              if (val == true) {
                _types.add('credit');
              } else {
                _types.remove('credit');
              }
            });
          },
        ),
        _buildCheckboxOption(
          title: 'Notifications / Ignored',
          subtitle: 'Informational SMS only (🔔)',
          icon: Icons.notifications_off_outlined,
          iconColor: AppColors.warningAmber,
          isSelected: _types.contains('ignored'),
          onChanged: (val) {
            setState(() {
              if (val == true) {
                _types.add('ignored');
              } else {
                _types.remove('ignored');
              }
            });
          },
        ),
      ],
    );
  }

  // --- 3. Category Tab (Multi-Select) with Manage Category action ---
  Widget _buildCategoryTab() {
    final allCategories = AppConstants.getAllCategories();
    final filteredCategories = _categorySearchQuery.isEmpty
        ? allCategories
        : allCategories.where((c) {
            final name = (c['name'] as String).toLowerCase();
            return name.contains(_categorySearchQuery.toLowerCase());
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _categorySearchController,
                  onChanged: (q) => setState(() => _categorySearchQuery = q),
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _categorySearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _categorySearchController.clear();
                              setState(() => _categorySearchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.tune_rounded, size: 18),
                tooltip: 'Manage Categories',
                onPressed: () {
                  ManageCategoriesModal.show(
                    context: context,
                    onCategoriesChanged: () {
                      setState(() {});
                    },
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _categories.isNotEmpty
                    ? '${_categories.length} selected'
                    : '${allCategories.length} categories',
                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
              if (_categories.isNotEmpty)
                InkWell(
                  onTap: () => setState(() => _categories.clear()),
                  child: const Text(
                    'Clear selection',
                    style: TextStyle(fontSize: 12, color: AppColors.debitRed),
                  ),
                )
              else
                InkWell(
                  onTap: () {
                    ManageCategoriesModal.show(
                      context: context,
                      onCategoriesChanged: () => setState(() {}),
                    );
                  },
                  child: const Text(
                    '+ Manage Categories',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: filteredCategories.length,
            itemBuilder: (context, index) {
              final cat = filteredCategories[index];
              final name = cat['name'] as String;
              final icon = cat['icon'] as IconData;
              final color = cat['color'] as Color;
              final isSelected = _categories.contains(name);

              return _buildCheckboxOption(
                title: name,
                icon: icon,
                iconColor: color,
                isSelected: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _categories.add(name);
                    } else {
                      _categories.remove(name);
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 4. Platform / Bank Tab (Multi-Select) ---
  Widget _buildPlatformTab() {
    final platforms = widget.availablePlatforms.isNotEmpty
        ? widget.availablePlatforms
        : AppConstants.supportedPlatforms;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Banks & Apps (Multi-select)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (_platforms.isNotEmpty)
              InkWell(
                onTap: () => setState(() => _platforms.clear()),
                child: const Text(
                  'Clear',
                  style: TextStyle(fontSize: 12, color: AppColors.debitRed),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ...platforms.map((platform) {
          final isSelected = _platforms.contains(platform);
          return _buildCheckboxOption(
            title: platform,
            icon: Icons.account_balance_wallet_outlined,
            iconColor: AppColors.primary,
            isSelected: isSelected,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _platforms.add(platform);
                } else {
                  _platforms.remove(platform);
                }
              });
            },
          );
        }),
      ],
    );
  }

  // --- 5. Amount Tab ---
  Widget _buildAmountTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        const Text(
          'Quick Amount Ranges',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildAmountPresetChip('Under ₹500', null, 500),
            _buildAmountPresetChip('₹500 - ₹2,000', 500, 2000),
            _buildAmountPresetChip('₹2,000 - ₹10,000', 2000, 10000),
            _buildAmountPresetChip('Above ₹10,000', 10000, null),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Custom Range',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min (₹)',
                  prefixText: '₹ ',
                  isDense: true,
                ),
                onChanged: (val) {
                  setState(() {
                    _minAmount = double.tryParse(val);
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max (₹)',
                  prefixText: '₹ ',
                  isDense: true,
                ),
                onChanged: (val) {
                  setState(() {
                    _maxAmount = double.tryParse(val);
                  });
                },
              ),
            ),
          ],
        ),
        if (_minAmount != null || _maxAmount != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _minAmount = null;
                  _maxAmount = null;
                  _minAmountController.clear();
                  _maxAmountController.clear();
                });
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear Amount Filter'),
              style: TextButton.styleFrom(foregroundColor: AppColors.debitRed),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAmountPresetChip(String label, double? min, double? max) {
    final isSelected = _minAmount == min && _maxAmount == max;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        setState(() {
          if (val) {
            _minAmount = min;
            _maxAmount = max;
            _minAmountController.text = min?.toInt().toString() ?? '';
            _maxAmountController.text = max?.toInt().toString() ?? '';
          } else {
            _minAmount = null;
            _maxAmount = null;
            _minAmountController.clear();
            _maxAmountController.clear();
          }
        });
      },
    );
  }

  // --- 6. Sort By Tab ---
  Widget _buildSortTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        const Text(
          'Sort Transactions By',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        _buildRadioOption<TransactionSortBy>(
          title: 'Date: Newest First',
          subtitle: 'Latest transactions at top',
          value: TransactionSortBy.dateNewest,
          groupValue: _sortBy,
          onChanged: (val) => setState(() => _sortBy = val!),
        ),
        _buildRadioOption<TransactionSortBy>(
          title: 'Date: Oldest First',
          subtitle: 'Oldest transactions at top',
          value: TransactionSortBy.dateOldest,
          groupValue: _sortBy,
          onChanged: (val) => setState(() => _sortBy = val!),
        ),
        _buildRadioOption<TransactionSortBy>(
          title: 'Amount: High to Low',
          subtitle: 'Largest amounts first',
          value: TransactionSortBy.amountHighToLow,
          groupValue: _sortBy,
          onChanged: (val) => setState(() => _sortBy = val!),
        ),
        _buildRadioOption<TransactionSortBy>(
          title: 'Amount: Low to High',
          subtitle: 'Smallest amounts first',
          value: TransactionSortBy.amountLowToHigh,
          groupValue: _sortBy,
          onChanged: (val) => setState(() => _sortBy = val!),
        ),
      ],
    );
  }

  // --- Helper Option Widgets ---
  Widget _buildRadioOption<T>({
    required String title,
    String? subtitle,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
    Widget? trailing,
  }) {
    final isSelected = value == groupValue;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.4) : Colors.transparent,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        visualDensity: VisualDensity.compact,
        leading: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.textTertiaryDark,
              width: 2,
            ),
          ),
          child: isSelected
              ? Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiaryDark),
              )
            : null,
        trailing: trailing,
        onTap: () => onChanged(value),
      ),
    );
  }

  Widget _buildCheckboxOption({
    required String title,
    String? subtitle,
    IconData? icon,
    Color? iconColor,
    required bool isSelected,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.4) : Colors.transparent,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        visualDensity: VisualDensity.compact,
        dense: true,
        leading: Checkbox(
          value: isSelected,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor ?? AppColors.primary),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiaryDark),
              )
            : null,
        onTap: () => onChanged(!isSelected),
      ),
    );
  }
}
