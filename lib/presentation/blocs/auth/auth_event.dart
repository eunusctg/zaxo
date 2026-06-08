import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired on app start to check the current auth status.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// User requests sign-in with email & password.
class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// User requests sign-up with email, password & display name.
class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

/// User requests Google sign-in.
class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// User requests sign-out.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// User requests an OTP to be sent to [phone].
class AuthOtpRequested extends AuthEvent {
  final String phone;

  const AuthOtpRequested({required this.phone});

  @override
  List<Object?> get props => [phone];
}

/// User submits the OTP [code] for verification.
class AuthOtpVerified extends AuthEvent {
  final String code;

  const AuthOtpVerified({required this.code});

  @override
  List<Object?> get props => [code];
}
