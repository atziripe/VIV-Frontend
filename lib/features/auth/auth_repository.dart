import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/config/env.dart';
import '../../firebase_options.dart';

/// Thrown when the user backs out of a native sign-in sheet — not an error
/// worth showing.
class SignInCancelled implements Exception {
  const SignInCancelled();
}

/// Firebase Auth is the identity provider: the backend only verifies the
/// Firebase ID token and auto-provisions the profile on the first call.
class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;
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
    final credential = OAuthProvider('apple.com').credential(
      idToken: apple.identityToken,
      rawNonce: rawNonce,
      accessToken: apple.authorizationCode,
    );
    final result = await _auth.signInWithCredential(credential);
    // Apple only shares the name on the very first sign-in.
    final name = [apple.givenName, apple.familyName].whereType<String>().join(' ').trim();
    if (name.isNotEmpty && (result.user?.displayName ?? '').isEmpty) {
      await result.user?.updateDisplayName(name);
    }
  }

  /// True when the account is linked to Sign in with Apple.
  bool get isAppleUser =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'apple.com') ?? false;

  /// Revokes VIV's Apple tokens — App Store rule 5.1.1(v) for account
  /// deletion. Apple needs a fresh authorization code (valid ~5 min), so this
  /// shows the Apple sheet again; call it right before deleting, while the
  /// Firebase user still exists. Needs the Apple provider in Firebase Console
  /// configured with a Services ID, Team ID, Key ID and private key.
  Future<void> revokeAppleAccess() async {
    final AuthorizationCredentialAppleID apple;
    try {
      apple = await SignInWithApple.getAppleIDCredential(scopes: const []);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) throw const SignInCancelled();
      rethrow;
    }
    await _auth.revokeTokenWithAuthorizationCode(apple.authorizationCode);
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
  (_) => AuthRepository(FirebaseAuth.instance),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);
