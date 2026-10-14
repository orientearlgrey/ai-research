import 'dart:math';

/// The experimental condition a participant is assigned to by Qualtrics.
enum Condition { manual, chatDefault, chatPrice }

Condition? _conditionFromParam(String? raw) {
  switch (raw) {
    case 'manual':
      return Condition.manual;
    case 'chat_default':
      return Condition.chatDefault;
    case 'chat_price':
      return Condition.chatPrice;
    default:
      return null;
  }
}

/// Thrown when the URL a participant arrived on is missing required
/// information. Surfaced as a dedicated error screen rather than a silent
/// default, since a broken experiment link should be obvious immediately
/// rather than silently producing unusable data.
class SessionConfigError implements Exception {
  final String message;
  const SessionConfigError(this.message);

  @override
  String toString() => 'SessionConfigError: $message';
}

class SessionConfig {
  final Condition condition;
  final String prolificId;
  final String sessionId;

  const SessionConfig({
    required this.condition,
    required this.prolificId,
    required this.sessionId,
  });

  bool get isChatCondition => condition != Condition.manual;

  /// Parses condition/Prolific ID/session id from [uri]'s query parameters.
  /// Takes an explicit [Uri] (rather than reading `Uri.base` itself) so this
  /// stays unit-testable without a browser; `Uri.base` is read exactly once,
  /// at the edge, in `main.dart`.
  factory SessionConfig.fromUri(Uri uri) {
    final params = uri.queryParameters;

    final condition = _conditionFromParam(params['condition']);
    if (condition == null) {
      throw SessionConfigError(
        'Missing or invalid "condition" query param '
        '(got "${params['condition']}"). Expected one of: '
        'manual, chat_default, chat_price.',
      );
    }

    final prolificId = _lookupProlificId(params);
    if (prolificId == null || prolificId.isEmpty) {
      throw const SessionConfigError(
        'Missing Prolific ID query param (expected "pid" or "prolific_pid", '
        'any letter casing).',
      );
    }

    final sessionId = params['sid'] ?? _generateFallbackSessionId();

    return SessionConfig(
      condition: condition,
      prolificId: prolificId,
      sessionId: sessionId,
    );
  }
}

String? _lookupProlificId(Map<String, String> params) {
  const candidateKeys = ['pid', 'prolific_pid'];
  for (final entry in params.entries) {
    if (candidateKeys.contains(entry.key.toLowerCase())) {
      return entry.value;
    }
  }
  return null;
}

String _generateFallbackSessionId() {
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final suffix = Random().nextInt(1 << 32);
  return 'sess_${timestamp}_$suffix';
}
