import 'package:equatable/equatable.dart';
import 'package:zaxo/domain/entities/status.dart';

abstract class StatusState extends Equatable {
  const StatusState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any status action.
class StatusInitial extends StatusState {
  const StatusInitial();
}

/// Statuses are loading.
class StatusLoading extends StatusState {
  const StatusLoading();
}

/// Statuses loaded successfully.
class StatusLoaded extends StatusState {
  /// All statuses grouped by user (most recent first per user).
  final List<Status> statuses;

  /// The user ID whose statuses are currently selected (for the viewer).
  /// Null when no user is selected.
  final String? selectedUserId;

  const StatusLoaded({
    required this.statuses,
    this.selectedUserId,
  });

  /// Returns statuses that belong to [selectedUserId].
  List<Status> get selectedUserStatuses {
    if (selectedUserId == null) return [];
    return statuses.where((s) => s.userId == selectedUserId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Returns unique user IDs that have statuses.
  List<String> get userIds {
    return statuses.map((s) => s.userId).toSet().toList();
  }

  /// Returns statuses grouped by user ID.
  Map<String, List<Status>> get statusesByUser {
    final map = <String, List<Status>>{};
    for (final status in statuses) {
      map.putIfAbsent(status.userId, () => []).add(status);
    }
    return map;
  }

  /// Returns whether the current user has any "my status" items.
  bool get hasMyStatus => statuses.isNotEmpty;

  StatusLoaded copyWith({
    List<Status>? statuses,
    String? selectedUserId,
    bool clearSelectedUserId = false,
  }) {
    return StatusLoaded(
      statuses: statuses ?? this.statuses,
      selectedUserId:
          clearSelectedUserId ? null : (selectedUserId ?? this.selectedUserId),
    );
  }

  @override
  List<Object?> get props => [statuses, selectedUserId];
}

/// Viewing a status with auto-advance timer.
class StatusViewing extends StatusState {
  /// All statuses for the user being viewed.
  final List<Status> statuses;

  /// Index of the currently displayed status within [statuses].
  final int currentIndex;

  const StatusViewing({
    required this.statuses,
    this.currentIndex = 0,
  });

  /// The currently displayed status.
  Status get currentStatus => statuses[currentIndex];

  /// Whether there is a next status to advance to.
  bool get hasNext => currentIndex < statuses.length - 1;

  /// Whether there is a previous status to go back to.
  bool get hasPrevious => currentIndex > 0;

  /// The user ID of the statuses being viewed.
  String get userId => statuses.isNotEmpty ? statuses.first.userId : '';

  StatusViewing copyWith({
    List<Status>? statuses,
    int? currentIndex,
  }) {
    return StatusViewing(
      statuses: statuses ?? this.statuses,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  @override
  List<Object?> get props => [statuses, currentIndex];
}

/// An error occurred during a status operation.
class StatusError extends StatusState {
  final String message;

  const StatusError(this.message);

  @override
  List<Object?> get props => [message];
}
