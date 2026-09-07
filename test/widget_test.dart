import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/localization/app_language.dart';
import 'package:expense_tracker/core/localization/app_localizations.dart';
import 'package:expense_tracker/presentation/modules/dashboard/ui/widgets/balance_card.dart';
import 'package:expense_tracker/presentation/modules/dashboard/ui/widgets/spend_meter.dart';
import 'package:expense_tracker/presentation/modules/main_navigation/ui/widgets/animated_bottom_nav_bar.dart';
import 'package:expense_tracker/presentation/modules/main_navigation/ui/widgets/rive_animated_icons.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    PathProviderPlatform.instance = FakePathProviderPlatform();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (methodCall) async => 1, // Granted
    );
  });

  group('UI Widgets Tests', () {
    testWidgets('BalanceCard renders correctly with currency and values', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLanguage.supportedLocales,
          home: const Scaffold(
            body: BalanceCard(
              totalBalance: 50000.0,
              totalIncome: 75000.0,
              totalExpense: 25000.0,
            ),
          ),
        ),
      );

      expect(find.textContaining('Total Balance'), findsOneWidget);
      expect(find.textContaining('50,000'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
    });

    testWidgets('SpendMeter renders correctly with budget calculation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLanguage.supportedLocales,
          theme: ThemeData(
            cardTheme: const CardThemeData(color: AppColors.darkCard),
          ),
          home: const Scaffold(
            body: SpendMeter(
              todaySpend: 1200.0,
              totalExpense: 25000.0,
              monthlyBudget: 50000.0,
            ),
          ),
        ),
      );

      expect(find.text('Monthly Budget'), findsOneWidget);
      expect(find.text('50% used'), findsOneWidget);
    });

    testWidgets('SpendMeter renders warning badge and triggers onManageCategoryBudgets', (tester) async {
      bool manageTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendMeter(
              todaySpend: 1500.0,
              totalExpense: 42000.0,
              monthlyBudget: 50000.0,
              warningOrExceededCount: 2,
              onManageCategoryBudgets: () {
                manageTapped = true;
              },
            ),
          ),
        ),
      );

      // Warning pill showing 2 alerts
      expect(find.text('2 alerts'), findsOneWidget);
      expect(find.text('Category Budgets'), findsOneWidget);

      // Tap on Category Budgets button
      await tester.tap(find.text('Category Budgets'));
      await tester.pumpAndSettle();

      expect(manageTapped, isTrue);
    });

    testWidgets('AnimatedBottomNavBar renders all items and switches selection correctly', (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: StatefulBuilder(
              builder: (context, setState) {
                return AnimatedBottomNavBar(
                  selectedIndex: selected,
                  onItemSelected: (index) {
                    setState(() {
                      selected = index;
                    });
                  },
                  items: const [
                    AnimatedNavItemData(tab: RiveNavTab.dashboard, label: 'Dashboard'),
                    AnimatedNavItemData(tab: RiveNavTab.transactions, label: 'Txns'),
                    AnimatedNavItemData(tab: RiveNavTab.khata, label: 'Khata'),
                    AnimatedNavItemData(tab: RiveNavTab.analytics, label: 'Analytics'),
                    AnimatedNavItemData(tab: RiveNavTab.reminders, label: 'Reminders'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Initially index 0 is selected, so 'Dashboard' text should not be visible
      expect(find.text('Dashboard'), findsNothing);
      // Other unselected labels should be visible
      expect(find.text('Txns'), findsOneWidget);
      expect(find.text('Khata'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Reminders'), findsOneWidget);

      // Tap on Khata (index 2)
      await tester.tap(find.text('Khata'));
      await tester.pumpAndSettle();

      // Now Khata is selected so its text is hidden, while Dashboard text is now visible
      expect(find.text('Khata'), findsNothing);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Txns'), findsOneWidget);
      expect(selected, 2);
    });
  });
}

