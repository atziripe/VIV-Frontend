import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viv/core/network/api_client.dart';
import 'package:viv/core/network/api_exception.dart';

class _FakeTokens implements TokenSource {
  int refreshes = 0;

  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    if (forceRefresh) refreshes++;
    return refreshes == 0 ? 'stale' : 'fresh';
  }

  @override
  Future<String?> appCheckToken() async => 'app-check';
}

/// Replies with canned responses and records the requests it saw.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final ResponseBody Function(RequestOptions o) handler;
  final seen = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? _, Future<void>? _) async {
    seen.add(o);
    return handler(o);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

ResponseBody _text(int status, String body) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: ['text/plain; charset=utf-8'],
  },
);

void main() {
  late _FakeTokens tokens;

  (ApiClient, _Adapter) build(ResponseBody Function(RequestOptions o) handler) {
    tokens = _FakeTokens();
    final dio = buildDio(tokens: tokens, baseUrl: 'https://api.test');
    final adapter = _Adapter(handler);
    dio.httpClientAdapter = adapter;
    return (ApiClient(dio), adapter);
  }

  test('attaches bearer and App Check headers', () async {
    final (api, adapter) = build((_) => _json(200, {'ok': true}));
    await api.get('/me');
    expect(adapter.seen.single.headers['Authorization'], 'Bearer stale');
    expect(adapter.seen.single.headers['X-Firebase-AppCheck'], 'app-check');
  });

  test('204 No Content becomes null', () async {
    final (api, _) = build((_) => ResponseBody.fromString('', 204));
    expect(await api.get('/training/weekly-plan/current', query: {'date': '2026-09-23'}), isNull);
  });

  test('plain-text error bodies surface as the message', () async {
    final (api, _) = build((_) => _text(400, 'cycle_duration out of range [15, 60]\n'));
    await expectLater(
      api.patch('/me', body: {'cycle_duration': '70'}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 400)
            .having((e) => e.message, 'message', 'cycle_duration out of range [15, 60]'),
      ),
    );
  });

  test('JSON error body (POST /checkins 409) keeps structure', () async {
    final (api, _) = build(
      (_) => _json(409, {'error': 'checkin_not_available_yet', 'next_available_at': '2026-09-28'}),
    );
    await expectLater(
      api.post('/checkins', body: {}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', 'checkin_not_available_yet')
            .having((e) => (e.body as Map)['next_available_at'], 'next', '2026-09-28'),
      ),
    );
  });

  test('401 refreshes the ID token once and replays', () async {
    final (api, adapter) = build(
      (o) => o.headers['Authorization'] == 'Bearer fresh'
          ? _json(200, {'id': 'u1'})
          : _text(401, 'invalid token'),
    );
    final res = await api.get('/me');
    expect(res, {'id': 'u1'});
    expect(tokens.refreshes, 1);
    expect(adapter.seen, hasLength(2));
  });

  test('a second 401 is not retried forever', () async {
    final (api, adapter) = build((_) => _text(401, 'invalid token'));
    await expectLater(
      api.get('/me'),
      throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'unauthorized', isTrue)),
    );
    expect(adapter.seen, hasLength(2));
  });
}
