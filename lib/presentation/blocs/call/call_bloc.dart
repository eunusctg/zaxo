import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zaxo/data/services/firebase_database_service.dart';
import 'package:zaxo/domain/entities/call.dart';
import 'package:zaxo/domain/entities/call_types.dart';

import 'call_event.dart';
import 'call_state.dart';

class CallBloc extends Bloc<CallEvent, CallState> {
  final FirebaseDatabaseService _dbService;

  StreamSubscription<List<Map<String, dynamic>>>? _callHistorySubscription;
  String? _currentUserId;

  CallBloc({
    required FirebaseDatabaseService dbService,
  })  : _dbService = dbService,
        super(const CallInitial()) {
    on<CallHistoryLoaded>(_onHistoryLoaded);
    on<CallInitiated>(_onCallInitiated);
    on<CallAccepted>(_onCallAccepted);
    on<CallRejected>(_onCallRejected);
    on<CallEnded>(_onCallEnded);
    on<CallFilterChanged>(_onFilterChanged);
  }

  // ── Factory: convert Firebase Map to Call entity ───────────────────────

  Call _mapToCall(Map<String, dynamic> data) {
    return Call(
      id: data['id'] as String? ?? '',
      callerId: data['callerId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      type: _parseCallType(data['type'] as String?),
      status: _parseCallStatus(data['status'] as String?),
      startTime: data['startTime'] != null
          ? DateTime.parse(data['startTime'] as String)
          : data['createdAt'] != null
              ? DateTime.parse(data['createdAt'] as String)
              : DateTime.now(),
      endTime: data['endTime'] != null
          ? DateTime.tryParse(data['endTime'] as String)
          : null,
      duration: data['duration'] as int?,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
    );
  }

  CallType _parseCallType(String? type) {
    switch (type) {
      case 'video':
        return CallType.video;
      default:
        return CallType.audio;
    }
  }

  CallStatus _parseCallStatus(String? status) {
    switch (status) {
      case 'ringing':
        return CallStatus.ringing;
      case 'ongoing':
        return CallStatus.ongoing;
      case 'ended':
        return CallStatus.ended;
      case 'missed':
        return CallStatus.missed;
      case 'rejected':
        return CallStatus.rejected;
      default:
        return CallStatus.ringing;
    }
  }

  String _callTypeToString(CallType type) {
    switch (type) {
      case CallType.audio:
        return 'audio';
      case CallType.video:
        return 'video';
    }
  }

  // ── Event Handlers ─────────────────────────────────────────────────────

  Future<void> _onHistoryLoaded(
    CallHistoryLoaded event,
    Emitter<CallState> emit,
  ) async {
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (_currentUserId == null) {
      emit(const CallHistoryLoadedState(calls: [], filter: CallFilter.all));
      return;
    }

    await _callHistorySubscription?.cancel();
    _callHistorySubscription =
        _dbService.getCallHistory(_currentUserId!).listen(
      (callMaps) {
        if (!isClosed) {
          final calls = callMaps.map(_mapToCall).toList();
          emit(CallHistoryLoadedState(
            calls: calls,
            filter: CallFilter.all,
          ));
        }
      },
      onError: (error) {
        if (!isClosed) {
          emit(CallError(error.toString()));
        }
      },
    );
  }

  Future<void> _onCallInitiated(
    CallInitiated event,
    Emitter<CallState> emit,
  ) async {
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (_currentUserId == null) return;

    try {
      final now = DateTime.now().toIso8601String();
      final callId = await _dbService.logCall({
        'callerId': _currentUserId,
        'receiverId': event.receiverId,
        'type': _callTypeToString(event.type),
        'status': 'ringing',
        'startTime': now,
      });

      emit(CallOngoing(
        callId: callId,
        type: event.type,
      ));
    } catch (e) {
      emit(CallError('Failed to initiate call: $e'));
    }
  }

  Future<void> _onCallAccepted(
    CallAccepted event,
    Emitter<CallState> emit,
  ) async {
    try {
      await _dbService.updateCall(event.callId, {
        'status': 'ongoing',
      });
    } catch (e) {
      emit(CallError('Failed to accept call: $e'));
    }
  }

  Future<void> _onCallRejected(
    CallRejected event,
    Emitter<CallState> emit,
  ) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _dbService.updateCall(event.callId, {
        'status': 'rejected',
        'endTime': now,
      });
    } catch (e) {
      emit(CallError('Failed to reject call: $e'));
    }
  }

  Future<void> _onCallEnded(
    CallEnded event,
    Emitter<CallState> emit,
  ) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _dbService.updateCall(event.callId, {
        'status': 'ended',
        'endTime': now,
      });
    } catch (e) {
      emit(CallError('Failed to end call: $e'));
    }
  }

  Future<void> _onFilterChanged(
    CallFilterChanged event,
    Emitter<CallState> emit,
  ) async {
    final currentState = state;
    if (currentState is CallHistoryLoadedState) {
      emit(currentState.copyWith(filter: event.filter));
    }
  }

  @override
  Future<void> close() {
    _callHistorySubscription?.cancel();
    return super.close();
  }
}
