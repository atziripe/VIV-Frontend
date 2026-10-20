import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/config/env.dart';
import '../../data/api/viv_api.dart';
import '../../firebase_options.dart';

/// Thrown when the user backs out of a native sign-in sheet — not an error
/// worth showing.
class SignInCancelled implements Exception {
  const SignInCancelled();
}

/// Firebase Auth is the identity provider: the backend only verifies the
/// Firebase ID token and auto-provisions the profile on the first call.
class AuthRepository {
  AuthRepository(this._auth, {this.onAppleAuthorized});

  final FirebaseAuth _auth;

  /// Receives Apple's authorization code once the Firebase session exists, so
  /// the backend can store it for revoking Apple access on account deletion.
  final Future<void> Function(String authorizationCode)? onAppleAuthorized;
  bool _googleInitialized = false;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signUpWithEmail(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await google.initialize(
        // iOS client from GoogleService-Info.plist (also GIDClientID in Info.plist).
        clientId: Platform.isIOS ? DefaultFirebaseOptions.ios.iosClientId : null,
        serverClientId: Env.googleServerClientId,
      );
      _googleInitialized = true;
    }
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) throw const SignInCancelled();
      rethrow;
    }
    final idToken = account.authentication.idToken;
    await _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
  }

  Future<void> signInWithApple() async {
    // Nonce protects against replay; Firebase checks the hashed value.
    final rawNonce = _randomNonce();
    final hashed = sha256.convert(utf8.encode(rawNonce)).toString();
    final AuthorizationCredentialAppleID apple;
    try {
      apple = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: hashed,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) throw const SignInCancelled();
      rethrow;
    }
    // The authorization code is single-use and goes to our backend, so it is
    // deliberately not passed to Firebase here.
    final credential = OAuthProvider('apple.com')
        .credential(idToken: apple.identityToken, rawNonce: rawNonce);
    final result = await _auth.signInWithCredential(credential);
    // Sent on every Apple sign-in: each one carries a fresh code, so accounts
    // created before this existed get covered too. Never blocks signing in.
    unawaited(
      onAppleAuthorized?.call(apple.authorizationCode).catchError((Object e) {
        debugPrint('Saving Apple credentials failed: $e');
      }),
    );
    // Apple only shares the name on the very first sign-in.
    final name = [apple.givenName, apple.familyName].whereType<String>().join(' ').trim();
    if (name.isNotEmpty && (result.user?.displayName ?? '').isEmpty) {
      await result.user?.updateDisplayName(name);
    }
  }

  Future<void> signOut() async {
    if (_googleInitialized) {
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }

  static String _randomNonce([int length = 32]) {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    FirebaseAuth.instance,
    onAppleAuthorized: (code) => ref.read(vivApiProvider).saveAppleAuthorizationCode(code),
  ),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);
