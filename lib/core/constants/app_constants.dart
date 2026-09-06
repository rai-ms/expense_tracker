import 'package:flutter/material.dart';

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

  /// Get category metadata by name or id
  static Map<String, dynamic> getCategory(String categoryKey) {
    final lower = categoryKey.toLowerCase();
    for (final cat in categories) {
      if (cat['id'] == lower ||
          (cat['name'] as String).toLowerCase() == lower) {
        return cat;
      }
    }
    return categories.last; // Other
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
