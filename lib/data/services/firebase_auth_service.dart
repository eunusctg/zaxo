/// Service class for Firebase Authentication.
///
/// Provides methods for email/password authentication, Google Sign-In,
/// phone authentication, and user state management.
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:zaxo/data/models/user_model.dart';

/// Handles all Firebase Authentication operations for Zaxo.
///
/// This service wraps [FirebaseAuth] and [GoogleSignIn] to provide a clean
/// API for sign-in, sign-up, sign-out, and auth state listening. It also
/// includes a placeholder for phone number authentication.
class FirebaseAuthService {
  // ── Singleton ──────────────────────────────────────────────────────────
  FirebaseAuthService._({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

  /// Default factory that uses production [FirebaseAuth] and [GoogleSignIn].
  factory FirebaseAuthService() => FirebaseAuthService._(
        firebaseAuth: FirebaseAuth.instance,
        googleSignIn: GoogleSignIn(),
      );

  /// Test-friendly factory with injectable dependencies.
  factory FirebaseAuthService.withDependencies({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  }) =>
      FirebaseAuthService._(
        firebaseAuth: firebaseAuth,
        googleSignIn: googleSignIn,
      );

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  // ── Auth State Stream ──────────────────────────────────────────────────

  /// Stream of the current Firebase [User].
  ///
  /// Emits `null` when the user is signed out. Use this to reactively
  /// update the UI based on authentication state.
  Stream<User?> getCurrentUser() => _firebaseAuth.authStateChanges();

  /// Returns the currently signed-in [User], or `null` if none.
  User? get currentUser => _firebaseAuth.currentUser;

  // ── Email / Password ───────────────────────────────────────────────────

  /// Signs in with an email and password.
  ///
  /// Returns the signed-in [User] on success.
  ///
  /// Throws [FirebaseAuthException] on failure with common codes:
  /// - `user-not-found` – no account with this email
  /// - `wrong-password` – incorrect password
  /// - `invalid-email` – malformed email
  /// - `user-disabled` – account disabled by admin
  /// - `too-many-requests` – rate-limited
  Future<User> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Sign-in succeeded but user is null.',
        );
      }
      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred during sign-in: $e',
      );
    }
  }

  /// Creates a new account with email, password, and display name.
  ///
  /// After creating the account, the display name is updated and a user
  /// profile document should be created in the database by the caller.
  ///
  /// Returns the newly created [User].
  ///
  /// Throws [FirebaseAuthException] on failure with common codes:
  /// - `email-already-in-use` – another account uses this email
  /// - `weak-password` – password is too short / simple
  /// - `invalid-email` – malformed email
  Future<User> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Account creation succeeded but user is null.',
        );
      }

      // Update the display name on the Firebase Auth profile.
      await user.updateDisplayName(name.trim());

      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred during sign-up: $e',
      );
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────

  /// Signs in with a Google account.
  ///
  /// On success, returns the [User]. If the Google account is new to Zaxo,
  /// the caller should create a user profile document in the database.
  ///
  /// Throws [FirebaseAuthException] on Firebase errors.
  /// Throws [GoogleSignInException] on Google-specific errors.
  Future<User> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow.
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in.
        throw FirebaseAuthException(
          code: 'sign-in-cancelled',
          message: 'Google sign-in was cancelled by the user.',
        );
      }

      // Obtain the auth details from the Google request.
      final googleAuth = await googleUser.authentication;

      // Create a new credential.
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential.
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Google sign-in succeeded but user is null.',
        );
      }

      // If this is a new user, update the display name from Google profile.
      if (userCredential.additionalUserInfo?.isNewUser == true &&
          user.displayName == null) {
        await user.updateDisplayName(googleUser.displayName);
      }

      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      if (e is FirebaseAuthException) rethrow;
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred during Google sign-in: $e',
      );
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────

  /// Signs the user out of both Firebase and Google.
  ///
  /// This method is idempotent – calling it when already signed out does
  /// nothing and returns successfully.
  Future<void> signOut() async {
    try {
      // Sign out from Google first (may throw if never signed in).
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore – the user may not have signed in with Google.
    }
    await _firebaseAuth.signOut();
  }

  // ── Phone Authentication (Placeholder) ─────────────────────────────────

  /// Sends a verification code to the given phone number.
  ///
  /// This is a placeholder implementation. When phone auth is fully
  /// implemented, this will use [FirebaseAuth.verifyPhoneNumber] with
  /// proper callback handling for SMS auto-retrieval and manual entry.
  ///
  /// Returns the verification ID needed to construct a [PhoneAuthCredential].
  Future<String> sendPhoneVerification({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) onVerificationCompleted,
    required void Function(FirebaseAuthException) onVerificationFailed,
    required void Function(String verificationId, int? resendToken)
        onCodeSent,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    String? verificationId;

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: (id, resendToken) {
        verificationId = id;
        onCodeSent(id, resendToken);
      },
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      timeout: timeout,
    );

    if (verificationId == null) {
      throw FirebaseAuthException(
        code: 'verification-id-null',
        message: 'Phone verification did not produce a verification ID.',
      );
    }
    return verificationId!;
  }

  /// Verifies the SMS code and signs the user in.
  ///
  /// Requires the [verificationId] from [sendPhoneVerification] and the
  /// [smsCode] entered by the user.
  ///
  /// Returns the authenticated [User].
  Future<User> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Phone verification succeeded but user is null.',
        );
      }
      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred during phone verification: $e',
      );
    }
  }

  // ── Password Reset ─────────────────────────────────────────────────────

  /// Sends a password reset email to the given address.
  ///
  /// Does not throw if the email does not exist (to prevent email enumeration).
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Failed to send password reset email: $e',
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Converts a Firebase [User] to a [UserModel] for local use.
  ///
  /// Callers should supplement this with additional data from the
  /// Realtime Database (e.g., `about`, `phone`, `publicKey`).
  UserModel toUserModel(User user) {
    return UserModel(
      id: user.uid,
      name: user.displayName ?? 'Zaxo User',
      email: user.email ?? '',
      phone: user.phoneNumber,
      avatarUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }
}
