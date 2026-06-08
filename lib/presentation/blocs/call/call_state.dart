import 'package:equatable/equatable.dart';
import 'package:zaxo/domain/entities/call.dart';
import 'package:zaxo/domain/entities/call_types.dart';
import 'package:zaxo/domain/entities/user.dart';

abstract class CallState extends Equatable {
  const CallState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any call action.
class CallInitial extends CallState {
  const CallInitial();
}

/// Call history has been loaded.
class CallHistoryLoadedState extends CallState {
  /// All call records.
  final List<Call> calls;

  /// Current filter applied to the history.
  final CallFilter filter;

  const CallHistoryLoadedState({
    required this.calls,
    required this.filter,
  });

  /// Returns calls filtered by the current [filter].
  List<Call> get filteredCalls {
    switch (filter) {
      case CallFilter.all:
        return calls;
      case CallFilter.missed:
        return calls.where((c) => c.isMissed).toList();
      case CallFilter.outgoing:
        return calls.where((c) => c.isOutgoing).toList();
      case CallFilter.incoming:
        return calls.where((c) => c.isIncoming).toList();
    }
  }

  CallHistoryLoadedState copyWith({
    List<Call>? calls,
    CallFilter? filter,
  }) {
    return CallHistoryLoadedState(
      calls: calls ?? this.calls,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [calls, filter];
}

/// An outgoing call is ringing on the receiver's side.
class CallOutgoing extends CallState {
  final User receiver;
  final CallType type;

  const CallOutgoing({
    required this.receiver,
    required this.type,
  });

  @override
  List<Object?> get props => [receiver, type];
}

/// An incoming call is ringing on the current user's side.
class CallIncoming extends CallState {
  final User caller;
  final CallType type;

  const CallIncoming({
    required this.caller,
    required this.type,
  });

  @override
  List<Object?> get props => [caller, type];
}

/// A call is currently ongoing.
class CallOngoing extends CallState {
  final String callId;
  final CallType type;

  /// Duration of the call so far in seconds.
  final int duration;

  const CallOngoing({
    required this.callId,
    required this.type,
    this.duration = 0,
  });

  CallOngoing copyWith({
    String? callId,
    CallType? type,
    int? duration,
  }) {
    return CallOngoing(
      callId: callId ?? this.callId,
      type: type ?? this.type,
      duration: duration ?? this.duration,
    );
  }

  @override
  List<Object?> get props => [callId, type, duration];
}

/// A call has ended.
class CallEndedState extends CallState {
  final String callId;

  /// Total duration of the call in seconds.
  final int duration;

  const CallEndedState({
    required this.callId,
    required this.duration,
  });

  @override
  List<Object?> get props => [callId, duration];
}

/// An error occurred during a call operation.
class CallError extends CallState {
  final String message;

  const CallError(this.message);

  @override
  List<Object?> get props => [message];
}
