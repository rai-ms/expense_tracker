import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_language.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/di/injection.dart';
import '../../core/services/route_service/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../modules/settings/bloc/locale_bloc.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LocaleBloc>(
      create: (_) => sl<LocaleBloc>()..add(LoadSavedLocaleEvent()),
      child: BlocBuilder<LocaleBloc, dynamic>(
        builder: (context, state) {
          final localeData = state.data as LocaleData?;
          final currentLocale = localeData?.locale ?? const Locale('en');
          final isRtl = localeData?.isRtl ?? false;
          final botToastBuilder = BotToastInit();

          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark, // Sleek fintech dark mode
            locale: currentLocale,
            supportedLocales: AppLanguage.supportedLanguages.map((l) => l.locale).toList(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: AppRouter.router,
            builder: (context, child) {
              child = botToastBuilder(context, child);
              return Directionality(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: child,
              );
            },
          );
        },
      ),
    );
  }
}
