import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fetch_client/fetch_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:app/features/coach/data/vercel_stream_parser.dart';
import 'package:app/features/coach/models/vercel_stream_event.dart';

part 'coach_stream_client.g.dart';

class CoachStreamClient {
  final Dio _dio;
  final TokenStorage? _tokenStorage;
  final VercelStreamParser _parser;

  CoachStreamClient(
    this._dio, {
    TokenStorage? tokenStorage,
    VercelStreamParser? parser,
  })  : _tokenStorage = tokenStorage,
        _parser = parser ?? VercelStreamParser();

  Stream<VercelStreamEvent> streamMessage(
    String conversationId,
    String content,
  ) {
    if (kIsWeb) {
      return _streamViaFetch(conversationId, content);
    }
    return _streamViaDio(conversationId, content);
  }

  Stream<VercelStreamEvent> _streamViaDio(
    String conversationId,
    String content,
  ) async* {
    final response = await _dio.post<ResponseBody>(
      '/coach/conversations/$conversationId/messages',
      data: {'content': content},
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
      ),
    );
    final body = response.data;
    if (body == null) return;
    yield* _parser.parse(body.stream);
  }

  Stream<VercelStreamEvent> _streamViaFetch(
    String conversationId,
    String content,
  ) async* {
    final token = await _tokenStorage?.getToken();
    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/coach/conversations/$conversationId/messages'),
    );
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Content-Type'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.body = jsonEncode({'content': content});

    final client = FetchClient(mode: RequestMode.cors);
    try {
      final response = await client.send(request);
      yield* _parser.parse(response.stream);
    } finally {
      client.close();
    }
  }
}

@riverpod
CoachStreamClient coachStreamClient(Ref ref) {
  return CoachStreamClient(
    ref.watch(dioProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
}
