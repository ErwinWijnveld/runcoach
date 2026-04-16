import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/features/coach/data/vercel_stream_parser.dart';
import 'package:app/features/coach/models/vercel_stream_event.dart';

part 'coach_stream_client.g.dart';

class CoachStreamClient {
  final Dio _dio;
  final VercelStreamParser _parser;

  CoachStreamClient(this._dio, [VercelStreamParser? parser])
      : _parser = parser ?? VercelStreamParser();

  Stream<VercelStreamEvent> streamMessage(
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
}

@riverpod
CoachStreamClient coachStreamClient(Ref ref) {
  return CoachStreamClient(ref.watch(dioProvider));
}
