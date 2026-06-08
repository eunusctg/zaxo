import 'package:zaxo/domain/entities/call.dart';
import 'package:zaxo/domain/entities/call_types.dart';

abstract class CallRepository {
  /// Create a new call record.
  Future<Call> createCall({
    required String receiverId,
    required CallType type,
  });

  /// Accept an incoming call.
  Future<void> acceptCall({required String callId});

  /// Reject an incoming call.
  Future<void> rejectCall({required String callId});

  /// End an ongoing call and record the duration.
  Future<void> endCall({
    required String callId,
    required int duration,
  });

  /// Get the call history for the current user.
  Future<List<Call>> getCallHistory();
}
