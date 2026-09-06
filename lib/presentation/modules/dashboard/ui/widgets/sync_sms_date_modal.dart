import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';

class SyncSmsDateModal extends StatefulWidget {
  final Function(DateTime fromDate, DateTime toDate, int limit) onSync;

  const SyncSmsDateModal({super.key, required this.onSync});

  @override
  State<SyncSmsDateModal> createState() => _SyncSmsDateModalState();
}

class _SyncSmsDateModalState extends State<SyncSmsDateModal> {
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  int _selectedPresetDays = 30;

  void _selectPreset(int days) {
    setState(() {
      _selectedPresetDays = days;
      _toDate = DateTime.now();
      _fromDate = DateTime.now().subtract(Duration(days: days));
    });
  }

  void _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'SELECT SYNC START DATE',
    );

    if (picked != null) {
      setState(() {
        _fromDate = DateTime(picked.year, picked.month, picked.day);
        _toDate = DateTime.now();
        _selectedPresetDays = -1; // Custom
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy');
    final diffDays = _toDate.difference(_fromDate).inDays;

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
              const Row(
                children: [
                  Icon(Icons.sync_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Sync SMS by Date',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose how far back you want SpendWise to scan your bank & UPI SMS messages:',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Quick Preset Pills
          const Text(
            'Quick Presets:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip('Last 7 Days', 7),
              _buildPresetChip('Last 15 Days', 15),
              _buildPresetChip('Last 30 Days (1 Mo)', 30),
              _buildPresetChip('Last 90 Days (3 Mo)', 90),
              _buildPresetChip('Last 180 Days (6 Mo)', 180),
              _buildPresetChip('1 Year (365 Days)', 365),
            ],
          ),
          const SizedBox(height: 20),

          // Selected Start Date Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fetch all messages since:',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(_fromDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '($diffDays days of financial history)',
                      style: const TextStyle(fontSize: 11, color: AppColors.primaryLight),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _pickCustomDate,
                  icon: const Icon(Icons.calendar_month_rounded, size: 16),
                  label: const Text('Calendar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Start Sync Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onSync(_fromDate, _toDate, 1000);
              },
              icon: const Icon(Icons.download_rounded),
              label: Text('Fetch & Sync Last $diffDays Days SMS'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, int days) {
    final isSelected = _selectedPresetDays == days;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) _selectPreset(days);
      },
    );
  }
}
