import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:zaxo/domain/entities/user.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  StreamSubscription<firebase_auth.User?>? _authStateSubscription;

  AuthBloc() : super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthOtpRequested>(_onOtpRequested);
    on<AuthOtpVerified>(_onOtpVerified);
  }

  User _firebaseUserToDomain(firebase_auth.User fbUser) {
    return User(
      id: fbUser.uid,
      name: fbUser.displayName ?? '',
      email: fbUser.email ?? '',
      phone: fbUser.phoneNumber,
      avatarUrl: fbUser.photoURL,
      isOnline: true,
      lastSeen: DateTime.now(),
      createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  Future<void> _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        emit(AuthAuthenticated(_firebaseUserToDomain(currentUser)));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSignInRequested(AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );
      if (credential.user != null) {
        emit(AuthAuthenticated(_firebaseUserToDomain(credential.user!)));
      } else {
        emit(const AuthUnauthenticated());
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(_mapError(e.code)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignUpRequested(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );
      if (credential.user != null) {
        await credential.user!.updateDisplayName(event.name.trim());
        emit(AuthAuthenticated(_firebaseUserToDomain(credential.user!)));
      } else {
        emit(const AuthUnauthenticated());
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(_mapError(e.code)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onGoogleSignInRequested(AuthGoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    // Google Sign-In requires setup - placeholder
    emit(const AuthError('Google Sign-In requires additional configuration'));
  }

  Future<void> _onSignOutRequested(AuthSignOutRequested event, Emitter<AuthState> emit) async {
    try {
      await _firebaseAuth.signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onOtpRequested(AuthOtpRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: event.phone,
        verificationCompleted: (credential) {
          _firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (e) {
          if (!isClosed) emit(AuthError(_mapError(e.code)));
        },
        codeSent: (verificationId, resendToken) {
          if (!isClosed) emit(AuthOtpSent(verificationId));
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!isClosed && state is! AuthOtpSent) emit(AuthOtpSent(verificationId));
        },
      );
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onOtpVerified(AuthOtpVerified event, Emitter<AuthState> emit) async {
    emit(const AuthOtpVerification());
    try {
      final verificationId = state is AuthOtpSent ? (state as AuthOtpSent).verificationId : '';
      if (verificationId.isEmpty) {
        emit(const AuthError('Verification ID not found'));
        return;
      }
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: event.code,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user != null) {
        emit(AuthAuthenticated(_firebaseUserToDomain(userCredential.user!)));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'invalid-email': return 'Invalid email address';
      case 'user-not-found': return 'No account found with this email';
      case 'wrong-password': return 'Incorrect password';
      case 'email-already-in-use': return 'Account already exists';
      case 'weak-password': return 'Password too weak (min 6 characters)';
      case 'too-many-requests': return 'Too many attempts. Try again later';
      case 'invalid-credential': return 'Invalid credentials';
      default: return 'Authentication error. Please try again.';
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
