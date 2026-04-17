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
    String content, {
    String? chipValue,
  }) {
    if (kIsWeb) {
      return _streamViaFetch(conversationId, content, chipValue: chipValue);
    }
    return _streamViaDio(conversationId, content, chipValue: chipValue);
  }

  Stream<VercelStreamEvent> _streamViaDio(
    String conversationId,
    String content, {
    String? chipValue,
  }) async* {
    final body = <String, dynamic>{'content': content};
    if (chipValue != null) body['chip_value'] = chipValue;
    final response = await _dio.post<ResponseBody>(
      '/coach/conversations/$conversationId/messages',
      data: body,
      options: Options(
        responseType: ResponseType.stream,
        // Generating a full training plan via the agent loop can produce long
        // silences between SSE chunks. Disable the per-chunk receive timeout
        // for the coach stream; connect timeout still enforces reachability.
        receiveTimeout: Duration.zero,
        sendTimeout: Duration.zero,
        headers: {'Accept': 'text/event-stream'},
      ),
    );
    final responseBody = response.data;
    if (responseBody == null) return;
    yield* _parser.parse(responseBody.stream);
  }

  Stream<VercelStreamEvent> _streamViaFetch(
    String conversationId,
    String content, {
    String? chipValue,
  }) async* {
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
    final bodyMap = <String, dynamic>{'content': content};
    if (chipValue != null) bodyMap['chip_value'] = chipValue;
    request.body = jsonEncode(bodyMap);

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
