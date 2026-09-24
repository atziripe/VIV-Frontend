import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A failed call to the VIV backend.
///
/// Most VIV error bodies are **plain text** (Go's `http.Error`), not JSON, so
/// [message] is the raw body string when there is one. The two JSON-error
/// endpoints keep their decoded body in [body].
class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.body, this.isNetwork = false});

  final int? statusCode;
  final String message;
  final Object? body;

  /// No response at all (offline, DNS, timeout).
  final bool isNetwork;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isBadRequest => statusCode == 400;
  bool get isServerError => (statusCode ?? 0) >= 500;

  factory ApiException.fromDio(DioException e) {
    final res = e.response;
    if (res == null) {
      return ApiException(
        message: switch (e.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.receiveTimeout ||
          DioExceptionType.sendTimeout => 'The server took too long to answer.',
          _ => 'Can\'t reach VIV right now. Check your connection.',
        },
        isNetwork: true,
      );
    }
    final data = res.data;
    final text = switch (data) {
      String s when s.trim().isNotEmpty => s.trim(),
      Map m when m['error'] is String => m['error'] as String,
      _ => res.statusMessage ?? 'Request failed',
    };
    return ApiException(statusCode: res.statusCode, message: text, body: data);
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Short, human copy for any error surfaced in the UI.
String userMessageFor(Object error) {
  if (error is ApiException) {
    if (error.isNetwork) return error.message;
    if (error.isUnauthorized) return 'Your session expired. Please log in again.';
    if (error.isServerError) return 'VIV hit a snag on our side. Try again in a moment.';
    return error.message;
  }
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'That email doesn\'t look right.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Email or password is incorrect.',
      'email-already-in-use' => 'There\'s already an account with that email. Try logging in.',
      'weak-password' => 'Use at least 8 characters for your password.',
      'too-many-requests' => 'Too many attempts. Wait a minute and try again.',
      'network-request-failed' => 'Can\'t reach VIV right now. Check your connection.',
      _ => error.message ?? 'Sign-in failed. Please try again.',
    };
  }
  return 'Something went wrong. Please try again.';
}
