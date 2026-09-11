import 'package:flutter/material.dart';

/// Document category metadata helper — categories for the PDF vault
class DocumentCategory {
  DocumentCategory._();

  static const List<String> all = [
    'All',
    'Salary',
    'Insurance',
    'Tax',
    'Medical',
    'Legal',
    'Other',
  ];

  static const Map<String, Map<String, dynamic>> _meta = {
    'Salary': {
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFF22C55E),
    },
    'Insurance': {
      'icon': Icons.health_and_safety_rounded,
      'color': Color(0xFF06B6D4),
    },
    'Tax': {
      'icon': Icons.receipt_long_rounded,
      'color': Color(0xFFF59E0B),
    },
    'Medical': {
      'icon': Icons.local_hospital_rounded,
      'color': Color(0xFFEF4444),
    },
    'Legal': {
      'icon': Icons.gavel_rounded,
      'color': Color(0xFF8B5CF6),
    },
    'Other': {
      'icon': Icons.folder_rounded,
      'color': Color(0xFF64748B),
    },
  };

  static Map<String, dynamic> get(String category) {
    return _meta[category] ??
        {'icon': Icons.folder_rounded, 'color': const Color(0xFF64748B)};
  }
}
