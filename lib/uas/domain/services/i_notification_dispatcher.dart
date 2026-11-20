import '../entities/notification_preference_entity.dart';

/// Platform-agnostic local OS notification dispatcher boundary.
abstract interface class INotificationDispatcher {
  Future<void> initialize();
  Future<bool> requestPermissionIfNeeded();
  Future<void> dispatchAlert(AlertEvaluationEntity alert);
}
