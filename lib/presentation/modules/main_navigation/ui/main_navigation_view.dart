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
import 'widgets/rive_animated_icons.dart';

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
              tab: RiveNavTab.dashboard,
              label: context.tr('dashboard'),
            ),
            AnimatedNavItemData(
              tab: RiveNavTab.transactions,
              label: context.tr('transactions'),
            ),
            AnimatedNavItemData(
              tab: RiveNavTab.khata,
              label: context.tr('khata'),
            ),
            AnimatedNavItemData(
              tab: RiveNavTab.analytics,
              label: context.tr('analytics'),
            ),
            AnimatedNavItemData(
              tab: RiveNavTab.reminders,
              label: context.tr('reminders'),
            ),
          ],
        ),
      ),
    );
  }
}

