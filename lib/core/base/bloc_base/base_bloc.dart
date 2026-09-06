import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc_event.dart';
import 'bloc_event_state.dart';

/// Base BLoC class providing standardized state emission helpers
abstract class BaseBloc<E extends BlocEvent, S>
    extends Bloc<E, BlocEventState<S>> {
  BaseBloc({S? initialData}) : super(BlocEventState.initial(initialData: initialData));

  /// Emit loading state
  @protected
  void emitLoading({S? data, String? message}) {
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    emit(state.copyWith(
      state: BlocState.loading,
      data: data ?? state.data,
      message: message,
    ));
  }

  /// Emit success state
  @protected
  void emitSuccess({S? data, String? message}) {
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    emit(state.copyWith(
      state: BlocState.success,
      data: data ?? state.data,
      message: message,
    ));
  }

  /// Emit failed state
  @protected
  void emitFailed({S? data, String? message, dynamic error}) {
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    emit(state.copyWith(
      state: BlocState.failed,
      data: data ?? state.data,
      message: message,
      error: error,
    ));
  }

  /// Emit no internet state
  @protected
  void emitNoInternet({S? data, String? message}) {
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    emit(state.copyWith(
      state: BlocState.noInternet,
      data: data ?? state.data,
      message: message,
    ));
  }

  /// Reset to initial state
  @protected
  void reset({S? initialData}) {
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    emit(BlocEventState.initial(initialData: initialData));
  }
}
