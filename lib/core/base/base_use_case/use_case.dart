/// Base use case for async operations
abstract class UseCase<T, P> {
  Future<T> call(P params);
}

/// Base use case for sync operations
abstract class UseCaseSync<T, P> {
  T call(P params);
}

/// No parameters class for use cases that don't require parameters
class NoParams {
  const NoParams();
}
