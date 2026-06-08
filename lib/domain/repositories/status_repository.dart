import 'package:zaxo/domain/entities/status.dart';

abstract class StatusRepository {
  /// Get all visible statuses from contacts.
  Future<List<Status>> getStatuses();

  /// Get statuses for a specific user.
  Future<List<Status>> getStatusesByUserId({required String userId});

  /// Create a new status.
  Future<Status> createStatus({
    required StatusMediaType type,
    required String content,
    String? mediaUrl,
    String? bgColor,
  });

  /// Mark a status as viewed by the current user.
  Future<void> markAsViewed({required String statusId});

  /// Delete a status.
  Future<void> deleteStatus({required String statusId});
}
