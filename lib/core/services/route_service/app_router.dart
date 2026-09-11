import 'package:go_router/go_router.dart';

import '../../../presentation/modules/analytics/controller/analytics_controller.dart';
import '../../../presentation/modules/documents/controller/documents_controller.dart';
import '../../../presentation/modules/export_pdf/controller/export_pdf_controller.dart';
import '../../../presentation/modules/khata/controller/khata_controller.dart';
import '../../../presentation/modules/khata_detail/controller/khata_detail_controller.dart';
import '../../../presentation/modules/main_navigation/controller/main_navigation_controller.dart';
import '../../../presentation/modules/reminders/controller/reminders_controller.dart';
import '../../../presentation/modules/sms_simulator/controller/sms_simulator_controller.dart';
import '../../../presentation/modules/splash/controller/splash_controller.dart';
import '../../../presentation/modules/transactions/controller/transactions_controller.dart';
import '../../constants/app_routes.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    errorBuilder: (context, state) => const MainNavigationController(),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashController(),
      ),
      GoRoute(
        path: AppRoutes.mainNavigation,
        builder: (context, state) => const MainNavigationController(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const MainNavigationController(),
      ),
      GoRoute(
        path: AppRoutes.transactions,
        builder: (context, state) => const TransactionsController(),
      ),
      GoRoute(
        path: AppRoutes.analytics,
        builder: (context, state) => const AnalyticsController(),
      ),
      GoRoute(
        path: AppRoutes.khata,
        builder: (context, state) => const KhataController(),
      ),
      GoRoute(
        path: AppRoutes.khataDetail,
        builder: (context, state) {
          final contactId = state.extra as int? ?? 0;
          return KhataDetailController(contactId: contactId);
        },
      ),
      GoRoute(
        path: AppRoutes.reminders,
        builder: (context, state) => const RemindersController(),
      ),
      GoRoute(
        path: AppRoutes.smsSimulator,
        builder: (context, state) => const SmsSimulatorController(),
      ),
      GoRoute(
        path: AppRoutes.exportPdf,
        builder: (context, state) => const ExportPdfController(),
      ),
      GoRoute(
        path: AppRoutes.documents,
        builder: (context, state) => const DocumentsController(),
      ),
    ],
  );
}
