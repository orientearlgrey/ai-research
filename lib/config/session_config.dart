import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// The experimental condition a participant is assigned to by Qualtrics.
enum Condition {
  manual('manual'),
  chatDefault('chat_default'),
  chatPrice('chat_price');

  /// Internal name. Never sent in the URL; see [stimCode].
  final String label;

  const Condition(this.label);

  /// Opaque code Qualtrics passes in the `stim` URL param instead of the
  /// condition name: the first [stimCodeLength] hex characters of
  /// `sha256(label)`. This keeps the condition from being readable in the
  /// iframe URL; it is obfuscation, not secrecy, since there are only a few
  /// possible values to hash.
  String get stimCode => sha256
      .convert(utf8.encode(label))
      .toString()
      .substring(0, stimCodeLength);
}

const int stimCodeLength = 6;
const String stimParam = 'stim';

Condition? _conditionFromStim(String? raw) {
  if (raw == null) return null;
  final code = raw.trim().toLowerCase();
  for (final condition in Condition.values) {
    if (condition.stimCode == code) return condition;
  }
  return null;
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

  /// Prolific's per-attempt session id (`psid`), if provided.
  final String? prolificSessionId;

  /// Identifier of the study this session belongs to (`study`), if provided.
  /// Lets one backend serve multiple studies.
  final String? studyId;

  const SessionConfig({
    required this.condition,
    required this.prolificId,
    required this.sessionId,
    this.prolificSessionId,
    this.studyId,
  });

  bool get isChatCondition => condition != Condition.manual;

  /// Parses condition, Prolific ID, and session/study ids from [uri]'s query parameters.
  /// Takes an explicit [Uri] (rather than reading `Uri.base` itself) so this
  /// stays unit-testable without a browser; `Uri.base` is read exactly once,
  /// at the edge, in `main.dart`.
  factory SessionConfig.fromUri(Uri uri) {
    final params = uri.queryParameters;

    final condition = _conditionFromStim(params[stimParam]);
    if (condition == null) {
      throw SessionConfigError(
        'Missing or invalid "$stimParam" query param '
        '(got "${params[stimParam]}").',
      );
    }

    final prolificId = _lookupProlificId(params);
    if (prolificId == null || prolificId.isEmpty) {
      throw const SessionConfigError(
        'Missing Prolific ID query param (expected "pid" or "prolific_pid", '
        'any letter casing).',
      );
    }

    final sessionId = _nonEmpty(params['sid']) ?? _generateFallbackSessionId();

    return SessionConfig(
      condition: condition,
      prolificId: prolificId,
      sessionId: sessionId,
      prolificSessionId: _nonEmpty(params['psid']),
      studyId: _nonEmpty(params['study']),
    );
  }
}

/// Qualtrics pipes an unset embedded-data field as an empty string, so an
/// empty value means "not provided".
String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
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
  // A literal, not `1 << 32`: on web, shifts are 32-bit so that evaluates to 0
  // and `nextInt(0)` throws a RangeError.
  final suffix = Random().nextInt(4294967296);
  return 'sess_${timestamp}_$suffix';
}
