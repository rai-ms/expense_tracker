import 'package:equatable/equatable.dart';

/// State enum for BLoC states
enum BlocState {
  none,
  loading,
  success,
  failed,
  noInternet,
}

/// Generic state class for BLoC states
class BlocEventState<T> extends Equatable {
  final BlocState state;
  final T? data;
  final String? message;
  final dynamic error;

  const BlocEventState({
    this.state = BlocState.none,
    this.data,
    this.message,
    this.error,
  });

  /// Initial state
  factory BlocEventState.initial({T? initialData}) => BlocEventState(
        data: initialData,
        state: BlocState.none,
      );

  /// Loading state
  factory BlocEventState.loading({T? data, String? message}) => BlocEventState(
        state: BlocState.loading,
        data: data,
        message: message,
      );

  /// Success state with data
  factory BlocEventState.success({T? data, String? message}) => BlocEventState(
        state: BlocState.success,
        data: data,
        message: message,
      );

  /// Failed state with error
  factory BlocEventState.failed({T? data, String? message, dynamic error}) =>
      BlocEventState(
        state: BlocState.failed,
        data: data,
        message: message,
        error: error,
      );

  /// No internet state
  factory BlocEventState.noInternet({T? data, String? message}) => BlocEventState(
        state: BlocState.noInternet,
        data: data,
        message: message ?? 'No internet connection',
      );

  /// Check if loading
  bool get isLoading => state == BlocState.loading;

  /// Check if success
  bool get isSuccess => state == BlocState.success;

  /// Check if failed
  bool get isFailed => state == BlocState.failed;

  /// Check if no internet
  bool get isNoInternet => state == BlocState.noInternet;

  /// Check if has data
  bool get hasData => data != null;

  /// Copy with new values
  BlocEventState<T> copyWith({
    BlocState? state,
    T? data,
    String? message,
    dynamic error,
  }) {
    return BlocEventState<T>(
      state: state ?? this.state,
      data: data ?? this.data,
      message: message ?? this.message,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [state, data, message, error];
}
