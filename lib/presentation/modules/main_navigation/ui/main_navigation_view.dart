import 'package:flutter/material.dart';

import '../../../../core/base/base_controller/widget_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../../analytics/controller/analytics_controller.dart';
import '../../dashboard/controller/dashboard_controller.dart';
import '../../khata/controller/khata_controller.dart';
import '../../reminders/controller/reminders_controller.dart';
import '../../transactions/controller/transactions_controller.dart';
import '../controller/main_navigation_controller.dart';

class MainNavigationView
    extends WidgetView<MainNavigationView, MainNavigationControllerState> {
  const MainNavigationView(super.ctr, {super.key});

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardController(),
      const TransactionsController(),
      const KhataController(),
      const AnalyticsController(),
      const RemindersController(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: ctr.currentIndex,
        children: screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.darkSurface,
            border: Border(
              top: BorderSide(color: AppColors.darkBorder, width: 0.8),
            ),
          ),
          child: NavigationBar(
            selectedIndex: ctr.currentIndex,
            onDestinationSelected: ctr.onTabSelected,
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.primary.withValues(alpha: 0.2),
            elevation: 0,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                label: 'Transactions',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded, color: AppColors.primary),
                label: 'KhataBook',
              ),
              NavigationDestination(
                icon: Icon(Icons.pie_chart_outline_rounded),
                selectedIcon: Icon(Icons.pie_chart_rounded, color: AppColors.primary),
                label: 'Analytics',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_none_rounded),
                selectedIcon: Icon(Icons.notifications_rounded, color: AppColors.primary),
                label: 'Reminders',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
