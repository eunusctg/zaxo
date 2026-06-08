import 'package:equatable/equatable.dart';
import 'package:zaxo/domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any auth action is taken.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// An auth operation is in progress.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is successfully authenticated.
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// User is not authenticated.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An auth error occurred.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// OTP has been sent; waiting for user to enter the code.
class AuthOtpSent extends AuthState {
  final String verificationId;

  const AuthOtpSent(this.verificationId);

  @override
  List<Object?> get props => [verificationId];
}

/// OTP verification is in progress.
class AuthOtpVerification extends AuthState {
  const AuthOtpVerification();
}
