import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/route_service/app_router.dart';
import '../../core/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final botToastBuilder = BotToastInit();

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to sleek fintech dark mode
      routerConfig: AppRouter.router,
      builder: (context, child) {
        child = botToastBuilder(context, child);
        return child;
      },
    );
  }
}
