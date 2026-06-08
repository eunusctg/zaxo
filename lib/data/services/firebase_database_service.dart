/// Service class for Firebase Realtime Database operations.
///
/// Provides real-time data access for chats, messages, users, statuses,
/// calls, and typing indicators using the Firebase Realtime Database.
library;

import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';

/// Centralised access to the Zaxo Firebase Realtime Database.
///
/// All data lives under the following top-level nodes:
/// - `chats/{chatId}` – chat metadata + last message
/// - `messages/{chatId}/{messageId}` – per-chat messages
/// - `users/{userId}` – user profiles & online state
/// - `statuses/{statusId}` – status (story) items
/// - `calls/{callId}` – call history entries
/// - `typing/{chatId}/{userId}` – typing indicators
///
/// The [DatabaseReference] is obtained from [FirebaseDatabase.instance].
class FirebaseDatabaseService {
  // ── Constructor ────────────────────────────────────────────────────────
  FirebaseDatabaseService({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;
  final _uuid = const Uuid();

  // ── Convenience refs ───────────────────────────────────────────────────

  DatabaseReference get _chatsRef => _database.ref('chats');
  DatabaseReference get _messagesRef => _database.ref('messages');
  DatabaseReference get _usersRef => _database.ref('users');
  DatabaseReference get _statusesRef => _database.ref('statuses');
  DatabaseReference get _callsRef => _database.ref('calls');
  DatabaseReference get _typingRef => _database.ref('typing');

  // ═══════════════════════════════════════════════════════════════════════
  //  MESSAGES
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns a real-time stream of messages for the given [chatId].
  ///
  /// Messages are ordered by `createdAt` ascending. Each emission contains
  /// a `List<Map<String, dynamic>>` with all current messages in the chat.
  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    return _messagesRef
        .child(chatId)
        .orderByChild('createdAt')
        .onValue
        .map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return <Map<String, dynamic>>[];

      final messages = <Map<String, dynamic>>[];
      if (snapshot.value is Map) {
        for (final entry in (snapshot.value as Map).entries) {
          final msg = Map<String, dynamic>.from(entry.value as Map);
          msg['id'] = entry.key;
          messages.add(msg);
        }
      }
      // Sort by createdAt string (ISO 8601 preserves sort order).
      messages.sort((a, b) =>
          (a['createdAt'] as String).compareTo(b['createdAt'] as String));
      return messages;
    });
  }

  /// Sends a message to the given [chatId].
  ///
  /// If the [message] map does not include an `id` or `createdAt` field,
  /// they are generated automatically. The chat's `lastMessage` and
  /// `lastMessageTime` are also updated.
  ///
  /// Returns the generated or provided message ID.
  Future<String> sendMessage(
    String chatId,
    Map<String, dynamic> message,
  ) async {
    try {
      final messageId = (message['id'] as String?) ?? _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final enrichedMessage = Map<String, dynamic>.from(message)
        ..putIfAbsent('id', () => messageId)
        ..putIfAbsent('chatId', () => chatId)
        ..putIfAbsent('createdAt', () => now)
        ..putIfAbsent('status', () => 'sent');

      // Write the message.
      await _messagesRef.child(chatId).child(messageId).set(enrichedMessage);

      // Update the chat's last message snapshot.
      await _chatsRef.child(chatId).update({
        'lastMessage': enrichedMessage,
        'lastMessageTime': now,
        'updatedAt': now,
      });

      return messageId;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CHATS
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns a real-time stream of chats where the given [userId] is a
  /// participant.
  ///
  /// Chats are ordered by `updatedAt` descending (most recent first).
  Stream<List<Map<String, dynamic>>> getChats(String userId) {
    return _chatsRef.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return <Map<String, dynamic>>[];

      final chats = <Map<String, dynamic>>[];
      if (snapshot.value is Map) {
        for (final entry in (snapshot.value as Map).entries) {
          final chat = Map<String, dynamic>.from(entry.value as Map);
          chat['id'] = entry.key;

          // Filter: only chats where this user is a participant.
          final participantIds = <String>[];
          if (chat['participantIds'] is List) {
            participantIds
                .addAll((chat['participantIds'] as List).cast<String>());
          }
          if (participantIds.contains(userId)) {
            chats.add(chat);
          }
        }
      }

      // Sort by updatedAt descending.
      chats.sort((a, b) {
        final aTime = a['updatedAt'] as String? ?? '';
        final bTime = b['updatedAt'] as String? ?? '';
        return bTime.compareTo(aTime);
      });

      return chats;
    });
  }

  /// Creates a new chat and returns its ID.
  ///
  /// The [chat] map should contain at least `participantIds`. If `id`,
  /// `createdAt`, or `updatedAt` are missing they are generated.
  Future<String> createChat(Map<String, dynamic> chat) async {
    try {
      final chatId = (chat['id'] as String?) ?? _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final enrichedChat = Map<String, dynamic>.from(chat)
        ..putIfAbsent('id', () => chatId)
        ..putIfAbsent('isGroup', () => false)
        ..putIfAbsent('createdAt', () => now)
        ..putIfAbsent('updatedAt', () => now);

      await _chatsRef.child(chatId).set(enrichedChat);
      return chatId;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  /// Partially updates a chat identified by [chatId].
  ///
  /// Only the keys present in [updates] are written; other fields are left
  /// untouched. `updatedAt` is automatically stamped.
  Future<void> updateChat(String chatId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _chatsRef.child(chatId).update(updates);
    } catch (e) {
      throw Exception('Failed to update chat: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  USERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Fetches a single user's data by [userId].
  ///
  /// Returns `null` if the user document does not exist.
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final snapshot = await _usersRef.child(userId).get();
      if (!snapshot.exists) return null;
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data['id'] = snapshot.key;
      return data;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Partially updates a user document identified by [userId].
  ///
  /// Only the keys present in [updates] are written.
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _usersRef.child(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Searches users by name (case-insensitive prefix match) or exact email.
  ///
  /// Because Firebase Realtime Database does not natively support full-text
  /// search, this method downloads all users and filters client-side. For
  /// production scale, consider integrating Algolia or ElasticSearch.
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final snapshot = await _usersRef.get();
      if (!snapshot.exists) return [];

      final results = <Map<String, dynamic>>[];
      final lowerQuery = query.toLowerCase().trim();

      if (snapshot.value is Map) {
        for (final entry in (snapshot.value as Map).entries) {
          final user = Map<String, dynamic>.from(entry.value as Map);
          user['id'] = entry.key;

          final name = (user['name'] as String? ?? '').toLowerCase();
          final email = (user['email'] as String? ?? '').toLowerCase();
          final phone = (user['phone'] as String? ?? '').toLowerCase();

          if (name.contains(lowerQuery) ||
              email.contains(lowerQuery) ||
              phone.contains(lowerQuery)) {
            results.add(user);
          }
        }
      }
      return results;
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  TYPING INDICATORS
  // ═══════════════════════════════════════════════════════════════════════

  /// Sets the typing state for a user in a chat.
  ///
  /// Writes `true` / `false` to `typing/{chatId}/{userId}`.
  Future<void> setStatusTyping(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    try {
      if (isTyping) {
        await _typingRef.child(chatId).child(userId).set(true);
      } else {
        await _typingRef.child(chatId).child(userId).remove();
      }
    } catch (e) {
      // Typing indicators are best-effort; don't throw.
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  ONLINE STATUS
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns a real-time stream of a user's online status.
  ///
  /// The stream emits a map containing `isOnline` (bool) and `lastSeen`
  /// (ISO-8601 String) fields.
  Stream<Map<String, dynamic>> getOnlineStatus(String userId) {
    return _usersRef.child(userId).onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) {
        return {'isOnline': false, 'lastSeen': null};
      }
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return {
        'isOnline': data['isOnline'] as bool? ?? false,
        'lastSeen': data['lastSeen'] as String?,
      };
    });
  }

  /// Sets the user's online status and last-seen timestamp.
  Future<void> setOnlineStatus(String userId, {required bool isOnline}) async {
    try {
      final updates = <String, dynamic>{
        'isOnline': isOnline,
        'lastSeen': DateTime.now().toIso8601String(),
      };
      await _usersRef.child(userId).update(updates);
    } catch (e) {
      // Best-effort; don't throw for online status updates.
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STATUSES (STORIES)
  // ═══════════════════════════════════════════════════════════════════════

  /// Uploads a status (story) item.
  ///
  /// If [status] does not include `id`, `createdAt`, or `expiresAt`,
  /// they are generated automatically (24-hour expiry by default).
  ///
  /// Returns the status ID.
  Future<String> uploadStatus(Map<String, dynamic> status) async {
    try {
      final statusId = (status['id'] as String?) ?? _uuid.v4();
      final now = DateTime.now();

      final enrichedStatus = Map<String, dynamic>.from(status)
        ..putIfAbsent('id', () => statusId)
        ..putIfAbsent('createdAt', () => now.toIso8601String())
        ..putIfAbsent(
            'expiresAt', () => now.add(const Duration(hours: 24)).toIso8601String())
        ..putIfAbsent('viewers', () => []);

      await _statusesRef.child(statusId).set(enrichedStatus);
      return statusId;
    } catch (e) {
      throw Exception('Failed to upload status: $e');
    }
  }

  /// Returns a real-time stream of statuses visible to the given [userId].
  ///
  /// This includes the user's own statuses plus statuses from their
  /// contacts that have not yet expired. Expired statuses are filtered
  /// client-side.
  Stream<List<Map<String, dynamic>>> getStatuses(String userId) {
    return _statusesRef.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return <Map<String, dynamic>>[];

      final now = DateTime.now();
      final results = <Map<String, dynamic>>[];

      if (snapshot.value is Map) {
        for (final entry in (snapshot.value as Map).entries) {
          final status = Map<String, dynamic>.from(entry.value as Map);
          status['id'] = entry.key;

          // Filter out expired statuses.
          final expiresAtStr = status['expiresAt'] as String?;
          if (expiresAtStr != null) {
            final expiresAt = DateTime.tryParse(expiresAtStr);
            if (expiresAt != null && expiresAt.isBefore(now)) continue;
          }

          results.add(status);
        }
      }

      // Sort by createdAt descending (newest first).
      results.sort((a, b) {
        final aTime = a['createdAt'] as String? ?? '';
        final bTime = b['createdAt'] as String? ?? '';
        return bTime.compareTo(aTime);
      });

      return results;
    });
  }

  /// Records that [userId] has viewed status [statusId].
  ///
  /// The user ID is appended to the status's `viewers` list (deduped).
  Future<void> viewStatus(String statusId, String userId) async {
    try {
      final ref = _statusesRef.child(statusId).child('viewers');
      final snapshot = await ref.get();

      final viewers = <String>[];
      if (snapshot.exists && snapshot.value is List) {
        viewers.addAll((snapshot.value as List).cast<String>());
      }

      if (!viewers.contains(userId)) {
        viewers.add(userId);
        await ref.set(viewers);
      }
    } catch (e) {
      throw Exception('Failed to view status: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CALLS
  // ═══════════════════════════════════════════════════════════════════════

  /// Logs a call entry to the database.
  ///
  /// If the [call] map does not include `id` or `createdAt`, they are
  /// generated automatically.
  ///
  /// Returns the call ID.
  Future<String> logCall(Map<String, dynamic> call) async {
    try {
      final callId = (call['id'] as String?) ?? _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final enrichedCall = Map<String, dynamic>.from(call)
        ..putIfAbsent('id', () => callId)
        ..putIfAbsent('createdAt', () => now);

      await _callsRef.child(callId).set(enrichedCall);
      return callId;
    } catch (e) {
      throw Exception('Failed to log call: $e');
    }
  }

  /// Returns a real-time stream of call history for the given [userId].
  ///
  /// Only calls where [userId] is the `callerId` or `receiverId` are
  /// included. Results are ordered by `createdAt` descending.
  Stream<List<Map<String, dynamic>>> getCallHistory(String userId) {
    return _callsRef.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return <Map<String, dynamic>>[];

      final calls = <Map<String, dynamic>>[];
      if (snapshot.value is Map) {
        for (final entry in (snapshot.value as Map).entries) {
          final call = Map<String, dynamic>.from(entry.value as Map);
          call['id'] = entry.key;

          final callerId = call['callerId'] as String? ?? '';
          final receiverId = call['receiverId'] as String? ?? '';

          if (callerId == userId || receiverId == userId) {
            calls.add(call);
          }
        }
      }

      calls.sort((a, b) {
        final aTime = a['createdAt'] as String? ?? '';
        final bTime = b['createdAt'] as String? ?? '';
        return bTime.compareTo(aTime);
      });

      return calls;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Creates a user document in the database.
  ///
  /// Call this after a successful sign-up to store user profile data
  /// beyond what Firebase Auth holds.
  Future<void> createUserDocument(Map<String, dynamic> userData) async {
    try {
      final userId = userData['id'] as String;
      await _usersRef.child(userId).set(userData);
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  /// Deletes a chat and all its messages.
  ///
  /// This is a destructive operation that removes the chat node and the
  /// associated messages node.
  Future<void> deleteChat(String chatId) async {
    try {
      await _messagesRef.child(chatId).remove();
      await _chatsRef.child(chatId).remove();
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  /// Updates the status of a specific message in a chat.
  Future<void> updateMessageStatus(
    String chatId,
    String messageId,
    String status,
  ) async {
    try {
      await _messagesRef
          .child(chatId)
          .child(messageId)
          .update({'status': status});
    } catch (e) {
      throw Exception('Failed to update message status: $e');
    }
  }

  /// Deletes a specific message from a chat (soft delete by marking as deleted).
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _messagesRef
          .child(chatId)
          .child(messageId)
          .update({'isDeleted': true});
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Partially updates a message identified by [chatId] and [messageId].
  ///
  /// Only the keys present in [updates] are written; other fields are left
  /// untouched.
  Future<void> updateMessage(
    String chatId,
    String messageId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _messagesRef.child(chatId).child(messageId).update(updates);
    } catch (e) {
      throw Exception('Failed to update message: $e');
    }
  }

  /// Updates a call entry identified by [callId].
  ///
  /// Only the keys present in [updates] are written.
  Future<void> updateCall(String callId, Map<String, dynamic> updates) async {
    try {
      await _callsRef.child(callId).update(updates);
    } catch (e) {
      throw Exception('Failed to update call: $e');
    }
  }

  /// Generates a new UUID v4.
  String generateId() => _uuid.v4();
}
