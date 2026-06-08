import '../../domain/entities/call.dart' as entity;
import '../../domain/entities/call_types.dart' show CallType, CallStatus;

/// Data model for Call with JSON serialization support.
class CallModel {
  final String id;
  final String callerId;
  final String receiverId;
  final CallType type;
  final CallStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration; // in seconds
  final DateTime createdAt;

  const CallModel({
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

  /// Parse CallType from string.
  static CallType parseCallType(String? type) {
    switch (type) {
      case 'audio':
        return CallType.audio;
      case 'video':
        return CallType.video;
      default:
        return CallType.audio;
    }
  }

  /// Parse CallStatus from string.
  static CallStatus parseCallStatus(String? status) {
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

  /// Convert CallType to string.
  static String callTypeToString(CallType type) {
    switch (type) {
      case CallType.audio:
        return 'audio';
      case CallType.video:
        return 'video';
    }
  }

  /// Convert CallStatus to string.
  static String callStatusToString(CallStatus status) {
    switch (status) {
      case CallStatus.ringing:
        return 'ringing';
      case CallStatus.ongoing:
        return 'ongoing';
      case CallStatus.ended:
        return 'ended';
      case CallStatus.missed:
        return 'missed';
      case CallStatus.rejected:
        return 'rejected';
    }
  }

  /// Create a CallModel from a JSON map.
  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['id'] as String,
      callerId: json['callerId'] as String,
      receiverId: json['receiverId'] as String,
      type: parseCallType(json['type'] as String?),
      status: parseCallStatus(json['status'] as String?),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      duration: json['duration'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert this CallModel to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callerId': callerId,
      'receiverId': receiverId,
      'type': callTypeToString(type),
      'status': callStatusToString(status),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a CallModel from a domain Call entity.
  factory CallModel.fromEntity(entity.Call call) {
    return CallModel(
      id: call.id,
      callerId: call.callerId,
      receiverId: call.receiverId,
      type: call.type,
      status: call.status,
      startTime: call.startTime,
      endTime: call.endTime,
      duration: call.duration,
      createdAt: call.createdAt,
    );
  }

  /// Convert this CallModel to a domain Call entity.
  entity.Call toEntity() {
    return entity.Call(
      id: id,
      callerId: callerId,
      receiverId: receiverId,
      type: type,
      status: status,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      createdAt: createdAt,
    );
  }

  CallModel copyWith({
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
    return CallModel(
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
}
