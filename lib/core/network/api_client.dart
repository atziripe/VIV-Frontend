import 'package:dio/dio.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'api_exception.dart';

/// Supplies the Firebase ID token and App Check token for each request.
/// Abstracted so tests can inject fakes without Firebase.
abstract interface class TokenSource {
  Future<String?> idToken({bool forceRefresh = false});
  Future<String?> appCheckToken();
}

class FirebaseTokenSource implements TokenSource {
  const FirebaseTokenSource();

  @override
  Future<String?> idToken({bool forceRefresh = false}) async =>
      FirebaseAuth.instance.currentUser?.getIdToken(forceRefresh);

  @override
  Future<String?> appCheckToken() async {
    try {
      return await FirebaseAppCheck.instance.getToken();
    } catch (e) {
      // App Check runs in monitor mode server-side, so a missing token must
      // never block a request.
      debugPrint('App Check token unavailable: $e');
      return null;
    }
  }
}

final tokenSourceProvider = Provider<TokenSource>((_) => const FirebaseTokenSource());

final dioProvider = Provider<Dio>((ref) {
  return buildDio(tokens: ref.watch(tokenSourceProvider));
});

Dio buildDio({required TokenSource tokens, String baseUrl = Env.apiBaseUrl}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
      // 4xx/5xx bodies are mostly text/plain; Dio decodes by Content-Type,
      // so they arrive as String and JSON bodies as Map/List.
      responseType: ResponseType.json,
    ),
  );
  dio.interceptors.add(_AuthInterceptor(tokens, dio));
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false,
        logPrint: (o) => debugPrint(o.toString()),
      ),
    );
  }
  return dio;
}

// A plain Interceptor, not QueuedInterceptor: the 401 replay below goes back
// through this same interceptor, and a queued error handler would deadlock
// waiting on its own replay if that also fails.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._tokens, this._dio);

  final TokenSource _tokens;
  final Dio _dio;

  static const _retriedKey = 'viv_retried_401';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokens.idToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    final appCheck = await _tokens.appCheckToken();
    if (appCheck != null) options.headers['X-Firebase-AppCheck'] = appCheck;
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // On a 401, force-refresh the ID token once and replay the request.
    final opts = err.requestOptions;
    if (err.response?.statusCode == 401 && opts.extra[_retriedKey] != true) {
      final fresh = await _tokens.idToken(forceRefresh: true);
      if (fresh != null) {
        opts.headers['Authorization'] = 'Bearer $fresh';
        opts.extra[_retriedKey] = true;
        try {
          return handler.resolve(await _dio.fetch<dynamic>(opts));
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
    }
    handler.next(err);
  }
}

/// Thin typed wrapper over [Dio] that converts failures to [ApiException]
/// and treats `204 No Content` as `null`.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>?> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<Map<String, dynamic>?> post(String path, {Object? body, Map<String, dynamic>? query}) =>
      _send(() => _dio.post<dynamic>(path, data: body, queryParameters: query));

  Future<Map<String, dynamic>?> patch(String path, {Object? body}) =>
      _send(() => _dio.patch<dynamic>(path, data: body));

  Future<Map<String, dynamic>?> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final res = await call();
      if (res.statusCode == 204) return null;
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      if (data == null || (data is String && data.isEmpty)) return null;
      throw ApiException(
        statusCode: res.statusCode,
        message: 'Unexpected response from server.',
        body: data,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(dioProvider)));
