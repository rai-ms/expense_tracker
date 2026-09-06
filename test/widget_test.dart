import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/presentation/modules/dashboard/ui/widgets/balance_card.dart';
import 'package:expense_tracker/presentation/modules/dashboard/ui/widgets/spend_meter.dart';
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
        const MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              totalBalance: 50000.0,
              totalIncome: 75000.0,
              totalExpense: 25000.0,
            ),
          ),
        ),
      );

      expect(find.text('Total Net Balance'), findsOneWidget);
      expect(find.textContaining('50,000'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
    });

    testWidgets('SpendMeter renders correctly with budget calculation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
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

      expect(find.text('Monthly Budget Meter'), findsOneWidget);
      expect(find.text('50% used'), findsOneWidget);
      expect(find.textContaining('1,200'), findsOneWidget);
    });
  });
}
