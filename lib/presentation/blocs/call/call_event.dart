import 'package:equatable/equatable.dart';
import 'package:zaxo/domain/entities/call_types.dart';

abstract class CallEvent extends Equatable {
  const CallEvent();

  @override
  List<Object?> get props => [];
}

/// Initiate a call to [receiverId] of the given [type].
class CallInitiated extends CallEvent {
  final String receiverId;
  final CallType type;

  const CallInitiated({
    required this.receiverId,
    required this.type,
  });

  @override
  List<Object?> get props => [receiverId, type];
}

/// Accept an incoming call.
class CallAccepted extends CallEvent {
  final String callId;

  const CallAccepted({required this.callId});

  @override
  List<Object?> get props => [callId];
}

/// Reject an incoming call.
class CallRejected extends CallEvent {
  final String callId;

  const CallRejected({required this.callId});

  @override
  List<Object?> get props => [callId];
}

/// End an ongoing call.
class CallEnded extends CallEvent {
  final String callId;

  const CallEnded({required this.callId});

  @override
  List<Object?> get props => [callId];
}

/// Load call history.
class CallHistoryLoaded extends CallEvent {
  const CallHistoryLoaded();
}

/// Change the filter applied to call history.
class CallFilterChanged extends CallEvent {
  final CallFilter filter;

  const CallFilterChanged({required this.filter});

  @override
  List<Object?> get props => [filter];
}
