import 'package:flutter/widgets.dart';

import 'package:app/core/i18n/build_context_l10n.dart';

/// Sentinel error codes stored on `CoachMessage.errorDetail` by the coach
/// providers when the client itself produced the error (timeout, connection
/// refused, etc). Server-provided error strings pass through unchanged.
///
/// Keeping these as opaque strings (not enums) so existing storage paths
/// — Freezed model, copyWith, JSON — don't need to change.
class CoachErrorCodes {
  static const connectionInterrupted = '__coach_err:connection_interrupted__';
  static const requestTimedOut = '__coach_err:request_timed_out__';
  static const cannotReachServer = '__coach_err:cannot_reach_server__';
  static const unknown = '__coach_err:unknown__';

  /// `'__coach_err:server_status:404'` etc — the suffix is the status code
  /// from `DioException.response?.statusCode`, or 'network' when unavailable.
  static String serverStatus(Object? status) =>
      '__coach_err:server_status:${status ?? 'network'}__';

  static String? _statusFromCode(String code) {
    const prefix = '__coach_err:server_status:';
    if (!code.startsWith(prefix) || !code.endsWith('__')) return null;
    return code.substring(prefix.length, code.length - 2);
  }
}

/// Translates a known error code (or returns the raw string unchanged when
/// the detail came from the server — those are already in the right
/// language because the backend honors `Accept-Language`).
String localizedCoachError(BuildContext context, String detail) {
  final l10n = context.l10n;
  switch (detail) {
    case CoachErrorCodes.connectionInterrupted:
      return l10n.chatErrorConnectionInterrupted;
    case CoachErrorCodes.requestTimedOut:
      return l10n.chatErrorRequestTimedOut;
    case CoachErrorCodes.cannotReachServer:
      return l10n.chatErrorCannotReachServer;
    case CoachErrorCodes.unknown:
      return l10n.chatErrorUnknown;
  }
  final status = CoachErrorCodes._statusFromCode(detail);
  if (status != null) return l10n.chatErrorServerStatus(status);
  return detail;
}
