import 'package:equatable/equatable.dart';

/// Base event class for BLoC events
abstract class BlocEvent extends Equatable {
  const BlocEvent();

  @override
  List<Object?> get props => [];
}
