import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zaxo/data/services/firebase_database_service.dart';
import 'package:zaxo/domain/entities/status.dart';

import 'status_event.dart';
import 'status_state.dart';

class StatusBloc extends Bloc<StatusEvent, StatusState> {
  final FirebaseDatabaseService _dbService;

  StreamSubscription<List<Map<String, dynamic>>>? _statusSubscription;
  String? _currentUserId;

  StatusBloc({
    required FirebaseDatabaseService dbService,
  })  : _dbService = dbService,
        super(const StatusInitial()) {
    on<StatusLoadRequested>(_onLoadRequested);
    on<StatusCreated>(_onCreated);
    on<StatusViewed>(_onViewed);
    on<StatusSelected>(_onSelected);
    on<StatusDismissed>(_onDismissed);
  }

  // ── Factory: convert Firebase Map to Status entity ─────────────────────

  Status _mapToStatus(Map<String, dynamic> data) {
    // Parse viewers list.
    final viewers = <String>[];
    if (data['viewers'] is List) {
      viewers.addAll((data['viewers'] as List).cast<String>());
    }

    // Determine if the current user has viewed this status.
    final isViewedByMe =
        _currentUserId != null && viewers.contains(_currentUserId);

    return Status(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String?,
      userPhotoUrl: data['userPhotoUrl'] as String?,
      type: _parseStatusMediaType(data['type'] as String?),
      mediaUrl: data['mediaUrl'] as String?,
      caption: data['caption'] as String?,
      text: data['text'] as String?,
      bgColor: data['bgColor'] as String?,
      font: data['font'] as String?,
      isViewedByMe: isViewedByMe,
      viewCount: viewers.length,
      viewers: viewers,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
      expiresAt: data['expiresAt'] != null
          ? DateTime.parse(data['expiresAt'] as String)
          : DateTime.now().add(const Duration(hours: 24)),
    );
  }

  StatusMediaType _parseStatusMediaType(String? type) {
    switch (type) {
      case 'image':
        return StatusMediaType.image;
      case 'video':
        return StatusMediaType.video;
      default:
        return StatusMediaType.text;
    }
  }

  String _statusTypeToString(StatusType type) {
    switch (type) {
      case StatusType.text:
        return 'text';
      case StatusType.image:
        return 'image';
      case StatusType.video:
        return 'video';
    }
  }

  // ── Event Handlers ─────────────────────────────────────────────────────

  Future<void> _onLoadRequested(
    StatusLoadRequested event,
    Emitter<StatusState> emit,
  ) async {
    emit(const StatusLoading());

    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (_currentUserId == null) {
      emit(const StatusLoaded(statuses: []));
      return;
    }

    await _statusSubscription?.cancel();
    _statusSubscription = _dbService.getStatuses(_currentUserId!).listen(
      (statusMaps) {
        if (!isClosed) {
          final statuses = statusMaps.map(_mapToStatus).toList();
          emit(StatusLoaded(statuses: statuses));
        }
      },
      onError: (error) {
        if (!isClosed) {
          emit(StatusError(error.toString()));
        }
      },
    );
  }

  Future<void> _onCreated(
    StatusCreated event,
    Emitter<StatusState> emit,
  ) async {
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (_currentUserId == null) return;

    try {
      final statusData = <String, dynamic>{
        'userId': _currentUserId,
        'type': _statusTypeToString(event.type),
        'content': event.content,
        'userName': FirebaseAuth.instance.currentUser?.displayName,
        'userPhotoUrl': FirebaseAuth.instance.currentUser?.photoURL,
      };

      if (event.mediaUrl != null) {
        statusData['mediaUrl'] = event.mediaUrl;
      }
      if (event.bgColor != null) {
        statusData['bgColor'] = event.bgColor;
      }
      // For text statuses, store the text content.
      if (event.type == StatusType.text) {
        statusData['text'] = event.content;
      } else {
        statusData['caption'] = event.content;
      }

      await _dbService.uploadStatus(statusData);
    } catch (e) {
      emit(StatusError('Failed to create status: $e'));
    }
  }

  Future<void> _onViewed(
    StatusViewed event,
    Emitter<StatusState> emit,
  ) async {
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (_currentUserId == null) return;

    try {
      await _dbService.viewStatus(event.statusId, _currentUserId!);
    } catch (e) {
      emit(StatusError('Failed to record status view: $e'));
    }
  }

  Future<void> _onSelected(
    StatusSelected event,
    Emitter<StatusState> emit,
  ) async {
    final currentState = state;
    if (currentState is StatusLoaded) {
      emit(currentState.copyWith(selectedUserId: event.userId));
    }
  }

  Future<void> _onDismissed(
    StatusDismissed event,
    Emitter<StatusState> emit,
  ) async {
    final currentState = state;
    if (currentState is StatusLoaded) {
      emit(currentState.copyWith(clearSelectedUserId: true));
    }
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    return super.close();
  }
}
