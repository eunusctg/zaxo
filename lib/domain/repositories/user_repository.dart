import 'package:zaxo/domain/entities/user.dart';

abstract class UserRepository {
  /// Get a user by their ID.
  Future<User> getUserById(String userId);

  /// Get all contacts for the current user.
  Future<List<User>> getContacts();

  /// Search users by name or phone number.
  Future<List<User>> searchUsers(String query);

  /// Update the current user's profile.
  Future<void> updateProfile(User user);
}
