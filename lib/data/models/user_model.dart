import '../../domain/entities/user.dart' as entity;

/// Data model for User with JSON serialization support.
class UserModel {
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

  const UserModel({
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

  /// Create a UserModel from a JSON map.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      about: json['about'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
      publicKey: json['publicKey'] as String?,
      fcmToken: json['fcmToken'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert this UserModel to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'about': about,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'publicKey': publicKey,
      'fcmToken': fcmToken,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a UserModel from a domain User entity.
  factory UserModel.fromEntity(entity.User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
      about: user.about,
      isOnline: user.isOnline,
      lastSeen: user.lastSeen,
      publicKey: user.publicKey,
      fcmToken: user.fcmToken,
      createdAt: user.createdAt,
    );
  }

  /// Convert this UserModel to a domain User entity.
  entity.User toEntity() {
    return entity.User(
      id: id,
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      about: about,
      isOnline: isOnline,
      lastSeen: lastSeen,
      publicKey: publicKey,
      fcmToken: fcmToken,
      createdAt: createdAt,
    );
  }

  UserModel copyWith({
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
    return UserModel(
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
}
