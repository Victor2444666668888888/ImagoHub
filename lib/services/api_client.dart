import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/photo.dart';
import '../models/search_filters.dart';
import 'http_factory.dart' if (dart.library.js_interop) 'http_factory_web.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  const ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

String defaultApiBase() {
  const configured = String.fromEnvironment('API_BASE_URL');
  if (configured.isNotEmpty) return configured;
  final host = kIsWeb
      ? Uri.base.host
      : defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : '127.0.0.1';
  return 'http://$host:8787';
}

class ApiClient {
  final http.Client client;
  final String baseUrl;
  String? token;
  ApiClient({http.Client? client, String? baseUrl})
    : client = client ?? createClient(),
      baseUrl = baseUrl ?? defaultApiBase();

  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse(
        '${baseUrl.replaceAll(RegExp(r'/$'), '')}$path',
      ).replace(queryParameters: query);
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response =
          await (method == 'GET'
                  ? client.get(uri, headers: headers)
                  : method == 'PATCH'
                  ? client.patch(uri, headers: headers, body: jsonEncode(body))
                  : client.post(uri, headers: headers, body: jsonEncode(body)))
              .timeout(const Duration(seconds: 30));
      dynamic data;
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        throw const ApiException('O servidor enviou uma resposta inválida.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          data is Map
              ? data['error'] ?? 'Não foi possível concluir a solicitação.'
              : 'Não foi possível concluir a solicitação.',
          response.statusCode,
        );
      }
      return data;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('A conexão demorou demais. Tente novamente.');
    } on Exception {
      throw const ApiException(
        'Não foi possível conectar. Confira sua conexão e tente novamente.',
      );
    }
  }

  Future<List<Photo>> feed(int page, String order) async =>
      (await request(
                '/photos',
                query: {'page': '$page', 'per_page': '20', 'order_by': order},
              )
              as List)
          .map((j) => Photo(Map<String, dynamic>.from(j)))
          .toList();
  Future<({List<Photo> photos, int total, int pages})> search(
    SearchFilters filters,
    int page,
  ) async {
    final data = await request('/search/photos', query: filters.params(page));
    return (
      photos: (data['results'] as List)
          .map((j) => Photo(Map<String, dynamic>.from(j)))
          .toList(),
      total: data['total'] as int,
      pages: data['total_pages'] as int,
    );
  }

  Future<Photo> detail(String id) async =>
      Photo(Map<String, dynamic>.from(await request('/photos/$id')));
  Future<void> trackDownload(Photo photo) async {
    final location = photo.links['download_location'] as String?;
    final uri = location == null ? null : Uri.tryParse(location);
    await request('/photos/${photo.id}/download', query: uri?.queryParameters);
  }

  Future<Uint8List> photoBytes(
    Photo photo, {
    required int width,
    int? height,
  }) async {
    // Images are public CDN resources; never attach account credentials to Unsplash.
    final imageClient = http.Client();
    try {
      final response = await imageClient
          .get(
            Uri.parse(
              photo.imageUrl(width: width, height: height, download: true),
            ),
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        throw const ApiException('Não foi possível baixar a imagem.');
      }
      return response.bodyBytes;
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException('O download falhou. Tente novamente.');
    } finally {
      imageClient.close();
    }
  }

  void close() => client.close();
}
