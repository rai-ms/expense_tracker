import 'package:flutter/foundation.dart';

/// Base service class that all services should extend
/// [T] is the return type of the init method
/// [P] is the parameter type for the init method
@protected
abstract class BaseService<T, P> {
  const BaseService();

  /// Initialize the service with optional parameters
  T init({P? param});

  /// Dispose the service
  void dispose() {}
}
