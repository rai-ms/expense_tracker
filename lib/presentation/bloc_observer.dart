import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/base/logger/app_logger.dart';

/// Application BLoC observer for logging state transitions and errors
class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    Log.d('BLoC Event: ${bloc.runtimeType} -> $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    Log.d('BLoC State: ${bloc.runtimeType} -> ${change.nextState}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    Log.e('BLoC Error in ${bloc.runtimeType}', error: error, stackTrace: stackTrace);
  }
}
