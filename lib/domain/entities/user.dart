import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? about;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? publicKey;
  final String? fcmToken;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.about,
    this.isOnline = false,
    this.lastSeen,
    this.publicKey,
    this.fcmToken,
    required this.createdAt,
  });

  /// Convenience getter for photo URL (alias for avatarUrl).
  String? get photoUrl => avatarUrl;

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? about,
    bool? isOnline,
    DateTime? lastSeen,
    String? publicKey,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      about: about ?? this.about,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      publicKey: publicKey ?? this.publicKey,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        avatarUrl,
        about,
        isOnline,
        lastSeen,
        publicKey,
        fcmToken,
        createdAt,
      ];
}
