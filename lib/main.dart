import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/base/logger/app_logger.dart';
import 'core/services/di/injection.dart';
import 'presentation/bloc_observer.dart';
import 'presentation/my_app/my_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Global BLoC observer
  Bloc.observer = AppBlocObserver();

  try {
    // Configure all services and ObjectBox store via GetIt
    await configureDependencies();
  } catch (e, stack) {
    Log.e('Initialization failed', error: e, stackTrace: stack);
  }

  runApp(const MyApp());
}
