import 'dart:convert';
import 'package:flutter/material.dart';

import '../services/objectbox_service/objectbox_service.dart';
import 'app_colors.dart';

/// Application wide constants, categories, and identifiers
class AppConstants {
  AppConstants._();

  static const String appName = 'SpendWise';
  static const String currencySymbol = '₹';

  // Categories with metadata
  static const List<Map<String, dynamic>> categories = [
    {
      'id': 'food',
      'name': 'Food & Dining',
      'icon': Icons.restaurant_rounded,
      'color': AppColors.food,
    },
    {
      'id': 'groceries',
      'name': 'Groceries',
      'icon': Icons.shopping_basket_rounded,
      'color': AppColors.groceries,
    },
    {
      'id': 'shopping',
      'name': 'Shopping',
      'icon': Icons.shopping_bag_rounded,
      'color': AppColors.shopping,
    },
    {
      'id': 'travel',
      'name': 'Travel & Fuel',
      'icon': Icons.directions_car_rounded,
      'color': AppColors.travel,
    },
    {
      'id': 'bills',
      'name': 'Bills & Utilities',
      'icon': Icons.receipt_long_rounded,
      'color': AppColors.bills,
    },
    {
      'id': 'entertainment',
      'name': 'Entertainment',
      'icon': Icons.movie_rounded,
      'color': AppColors.entertainment,
    },
    {
      'id': 'investment',
      'name': 'Investments',
      'icon': Icons.trending_up_rounded,
      'color': AppColors.investment,
    },
    {
      'id': 'health',
      'name': 'Health & Medical',
      'icon': Icons.medical_services_rounded,
      'color': AppColors.health,
    },
    {
      'id': 'salary',
      'name': 'Salary & Income',
      'icon': Icons.account_balance_wallet_rounded,
      'color': AppColors.salary,
    },
    {
      'id': 'other',
      'name': 'Other / Transfer',
      'icon': Icons.category_rounded,
      'color': AppColors.other,
    },
  ];

  static const String customCategoriesKey = 'user_custom_categories_list';
  static const String customCategoriesRichKey = 'user_custom_categories_rich_json';

  /// Get all categories (Standard + dynamic user custom categories from ObjectBox)
  static List<Map<String, dynamic>> getAllCategories() {
    final List<Map<String, dynamic>> all = List.from(categories);
    if (ObjectBoxService.instance.isInitialized) {
      // 1. Try loading rich custom categories JSON
      final richJson = ObjectBoxService.instance.getSetting(customCategoriesRichKey);
      final Set<String> processedNames = {};

      if (richJson != null && richJson.trim().isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(richJson);
          for (final item in decoded) {
            final map = item as Map<String, dynamic>;
            final name = map['name'] as String? ?? '';
            if (name.isNotEmpty &&
                !all.any((c) => (c['name'] as String).toLowerCase() == name.toLowerCase())) {
              final iconCode = map['iconCode'] as int? ?? Icons.label_rounded.codePoint;
              final iconFont = map['iconFont'] as String? ?? 'MaterialIcons';
              final colorVal = map['color'] as int? ?? AppColors.primaryLight.toARGB32();

              all.insert(all.length - 1, {
                'id': name.toLowerCase().replaceAll(' ', '_'),
                'name': name,
                // ignore: non_const_argument_for_const_parameter
                'icon': IconData(iconCode, fontFamily: iconFont),
                'color': Color(colorVal),
                'isCustom': true,
              });
              processedNames.add(name.toLowerCase());
            }
          }
        } catch (_) {}
      }

      // 2. Backward compatibility with plain string list
      final customNames =
          ObjectBoxService.instance.getStringListSetting(customCategoriesKey);
      for (final name in customNames) {
        if (!processedNames.contains(name.toLowerCase()) &&
            !all.any((c) => (c['name'] as String).toLowerCase() == name.toLowerCase())) {
          all.insert(all.length - 1, {
            'id': name.toLowerCase().replaceAll(' ', '_'),
            'name': name,
            'icon': Icons.label_rounded,
            'color': AppColors.primaryLight,
            'isCustom': true,
          });
        }
      }
    }
    return all;
  }

  /// Add a new custom category
  static void addCustomCategory({
    required String name,
    IconData? icon,
    Color? color,
  }) {
    if (!ObjectBoxService.instance.isInitialized) return;
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    // Load existing rich categories
    final List<Map<String, dynamic>> richList = _getStoredRichCategories();
    final existingIndex = richList.indexWhere(
      (c) => (c['name'] as String).toLowerCase() == trimmedName.toLowerCase(),
    );

    final item = {
      'name': trimmedName,
      'iconCode': (icon ?? Icons.label_rounded).codePoint,
      'iconFont': (icon ?? Icons.label_rounded).fontFamily ?? 'MaterialIcons',
      'color': (color ?? AppColors.primaryLight).toARGB32(),
    };

    if (existingIndex >= 0) {
      richList[existingIndex] = item;
    } else {
      richList.add(item);
    }

    _persistRichCategories(richList);
  }

  /// Update an existing custom category
  static void updateCustomCategory({
    required String oldName,
    required String newName,
    IconData? icon,
    Color? color,
  }) {
    if (!ObjectBoxService.instance.isInitialized) return;
    final trimmedNew = newName.trim();
    if (trimmedNew.isEmpty) return;

    final List<Map<String, dynamic>> richList = _getStoredRichCategories();
    final index = richList.indexWhere(
      (c) => (c['name'] as String).toLowerCase() == oldName.trim().toLowerCase(),
    );

    final item = {
      'name': trimmedNew,
      'iconCode': (icon ?? Icons.label_rounded).codePoint,
      'iconFont': (icon ?? Icons.label_rounded).fontFamily ?? 'MaterialIcons',
      'color': (color ?? AppColors.primaryLight).toARGB32(),
    };

    if (index >= 0) {
      richList[index] = item;
    } else {
      richList.add(item);
    }

    _persistRichCategories(richList);
  }

  /// Delete a custom category
  static void deleteCustomCategory(String name) {
    if (!ObjectBoxService.instance.isInitialized) return;
    final trimmed = name.trim().toLowerCase();

    final List<Map<String, dynamic>> richList = _getStoredRichCategories();
    richList.removeWhere((c) => (c['name'] as String).toLowerCase() == trimmed);
    _persistRichCategories(richList);

    // Also update legacy list
    final legacyList = ObjectBoxService.instance.getStringListSetting(customCategoriesKey);
    legacyList.removeWhere((n) => n.trim().toLowerCase() == trimmed);
    ObjectBoxService.instance.setStringListSetting(customCategoriesKey, legacyList);
  }

  static List<Map<String, dynamic>> _getStoredRichCategories() {
    if (!ObjectBoxService.instance.isInitialized) return [];
    final richJson = ObjectBoxService.instance.getSetting(customCategoriesRichKey);
    if (richJson == null || richJson.trim().isEmpty) {
      // Migrate from legacy list
      final legacyList = ObjectBoxService.instance.getStringListSetting(customCategoriesKey);
      return legacyList
          .map((n) => {
                'name': n,
                'iconCode': Icons.label_rounded.codePoint,
                'iconFont': 'MaterialIcons',
                'color': AppColors.primaryLight.toARGB32(),
              })
          .toList();
    }
    try {
      final List<dynamic> decoded = jsonDecode(richJson);
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static void _persistRichCategories(List<Map<String, dynamic>> list) {
    final jsonStr = jsonEncode(list);
    ObjectBoxService.instance.setSetting(customCategoriesRichKey, jsonStr);

    // Keep legacy string list in sync
    final names = list.map((c) => c['name'] as String).toList();
    ObjectBoxService.instance.setStringListSetting(customCategoriesKey, names);
  }

  /// Get category metadata by name or id
  static Map<String, dynamic> getCategory(String categoryKey) {
    final lower = categoryKey.toLowerCase();
    for (final cat in getAllCategories()) {
      if (cat['id'] == lower ||
          (cat['name'] as String).toLowerCase() == lower) {
        return cat;
      }
    }
    return {
      'id': lower,
      'name': categoryKey,
      'icon': Icons.label_rounded,
      'color': AppColors.primaryLight,
      'isCustom': true,
    };
  }

  /// Supported UPI Platforms
  static const List<String> supportedPlatforms = [
    'Google Pay',
    'PhonePe',
    'Paytm',
    'Cred',
    'Amazon Pay',
    'BHIM',
    'HDFC Bank',
    'SBI',
    'ICICI Bank',
    'Axis Bank',
    'Kotak Bank',
    'PNB',
    'Slice',
  ];
}

