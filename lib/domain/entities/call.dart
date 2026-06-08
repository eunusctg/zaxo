import 'package:equatable/equatable.dart';
import 'package:zaxo/domain/entities/call_types.dart';

class Call extends Equatable {
  final String id;
  final String callerId;
  final String receiverId;
  final CallType type;
  final CallStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration;
  final DateTime createdAt;

  const Call({
    required this.id,
    required this.callerId,
    required this.receiverId,
    this.type = CallType.audio,
    this.status = CallStatus.ringing,
    required this.startTime,
    this.endTime,
    this.duration,
    required this.createdAt,
  });

  /// Whether the call was missed by the receiver.
  bool get isMissed => status == CallStatus.missed;

  /// Whether this was an outgoing call from the current user.
  /// Should be compared against the current user's ID in the presentation layer.
  bool get isOutgoing => status == CallStatus.ended;

  /// Whether this was an incoming call.
  bool get isIncoming => status == CallStatus.ended;

  Call copyWith({
    String? id,
    String? callerId,
    String? receiverId,
    CallType? type,
    CallStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    DateTime? createdAt,
  }) {
    return Call(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        callerId,
        receiverId,
        type,
        status,
        startTime,
        endTime,
        duration,
        createdAt,
      ];
}
