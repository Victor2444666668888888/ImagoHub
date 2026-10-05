import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:imagohub/services/api_client.dart';
import 'package:imagohub/state/app_state.dart';

Future<AppState> testState({
  Future<http.Response> Function(http.Request)? respond,
  bool clearStorage = true,
  bool authenticated = true,
  bool seedLibrary = true,
}) async {
  if (clearStorage) {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  }
  final references =
      jsonDecode(
            await rootBundle.loadString('assets/data/reference_photos.json'),
          )
          as List;
  final accounts = <String, Map<String, dynamic>>{};
  final client = MockClient(
    respond ??
        (request) async {
          final path = request.url.path;
          if (path == '/search/photos') {
            return http.Response(
              jsonEncode({
                'results': [
                  references[4],
                  references[7],
                  references[5],
                  references[6],
                ],
                'total': 4,
                'total_pages': 1,
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          if (path.endsWith('/download')) {
            return http.Response(
              '{"url":"https://images.unsplash.com/test"}',
              200,
            );
          }
          if (path.startsWith('/photos/')) {
            final photo = references.firstWhere(
              (p) => p['id'] == path.split('/').last,
              orElse: () => references.first,
            );
            return http.Response(
              jsonEncode(photo),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          if (path == '/photos') {
            return http.Response(
              jsonEncode(references),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          if (path == '/auth/register') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            accounts[body['email']] = {
              'name': body['name'],
              'username': body['username'] ?? body['name'],
            };
            return http.Response(
              '{"message":"Conta criada."}',
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          if (path == '/auth/login') {
            final body = jsonDecode(request.body);
            if (body['password'] == 'wrongpass') {
              return http.Response(
                '{"error":"E-mail ou senha incorretos."}',
                401,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }
            return http.Response(
              jsonEncode({
                'token': 'test-token',
                'user': {
                  'id': body['email'],
                  'name': 'Victor Bonissoni',
                  'email': body['email'],
                  ...?accounts[body['email']],
                },
              }),
              200,
            );
          }
          if (path == '/auth/profile') {
            return http.Response(
              jsonEncode({
                'user': {
                  'id': 'user@example.com',
                  ...jsonDecode(request.body) as Map<String, dynamic>,
                },
              }),
              200,
            );
          }
          if (path == '/auth/logout') return http.Response('{}', 200);
          return http.Response('{"error":"Não encontrado."}', 404);
        },
  );
  final state = AppState(
    api: ApiClient(client: client, baseUrl: 'http://localhost:8787'),
    persistSessions: false,
  );
  if (authenticated) {
    state.user = {
      'id': 'user@example.com',
      'name': 'Victor Bonissoni',
      'email': 'user@example.com',
    };
    state.api.token = 'test-token';
    const libraryKey = 'imagohub.library.v1.user@example.com';
    if (seedLibrary && await state.preferences.getString(libraryKey) == null) {
      // Reference data belongs to the test fixture, never to a visitor profile.
      await state.preferences.setString(
        libraryKey,
        jsonEncode({
          'favorites': [
            0,
            4,
            6,
            7,
            5,
            2,
            3,
            1,
          ].map((i) => references[i]['id']).toList(),
          'folders': [
            {
              'id': 'natureza',
              'name': 'Natureza',
              'photoIds': [
                4,
                0,
                6,
                7,
                5,
                2,
                3,
                1,
              ].map((i) => references[i]['id']).toList(),
            },
            {
              'id': 'projetos',
              'name': 'Projetos criativos',
              'photoIds': [
                3,
                5,
                2,
                4,
                1,
              ].map((i) => references[i]['id']).toList(),
            },
            {
              'id': 'depois',
              'name': 'Para usar depois',
              'photoIds': [7, 1, 0].map((i) => references[i]['id']).toList(),
            },
          ],
          'photos': references,
          'profile': {
            'name': 'Victor Bonissoni',
            'username': '@victorbonissoni',
            'email': 'user@example.com',
            'bio': 'Fotografia, natureza e novas ideias.',
          },
        }),
      );
    }
  }
  await state.initialize();
  return state;
}
