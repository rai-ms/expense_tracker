import 'package:flutter/material.dart';

import '../../../../core/base/base_controller/widget_view.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../analytics/controller/analytics_controller.dart';
import '../../dashboard/controller/dashboard_controller.dart';
import '../../khata/controller/khata_controller.dart';
import '../../reminders/controller/reminders_controller.dart';
import '../../transactions/controller/transactions_controller.dart';
import '../controller/main_navigation_controller.dart';
import 'widgets/animated_bottom_nav_bar.dart';

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
        child: AnimatedBottomNavBar(
          selectedIndex: ctr.currentIndex,
          onItemSelected: ctr.onTabSelected,
          items: [
            AnimatedNavItemData(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: context.tr('dashboard'),
            ),
            AnimatedNavItemData(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              label: context.tr('transactions'),
            ),
            AnimatedNavItemData(
              icon: Icons.menu_book_outlined,
              activeIcon: Icons.menu_book_rounded,
              label: context.tr('khata'),
            ),
            AnimatedNavItemData(
              icon: Icons.pie_chart_outline_rounded,
              activeIcon: Icons.pie_chart_rounded,
              label: context.tr('analytics'),
            ),
            AnimatedNavItemData(
              icon: Icons.notifications_none_rounded,
              activeIcon: Icons.notifications_rounded,
              label: context.tr('reminders'),
            ),
          ],
        ),
      ),
    );
  }
}
