import 'package:ai_research/config/session_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionConfig.fromUri', () {
    test('parses a real Prolific-style id and generates a fallback sid', () {
      final config = SessionConfig.fromUri(
        Uri.parse('http://localhost/?stim=36bde6&pid=676183cb707ba8182ab23541'),
      );

      expect(config.condition, Condition.manual);
      expect(config.prolificId, '676183cb707ba8182ab23541');
      expect(config.sessionId, startsWith('sess_'));
    });

    test('uses the sid query param when present', () {
      final config = SessionConfig.fromUri(
        Uri.parse('http://localhost/?stim=64e213&pid=A&sid=abc'),
      );

      expect(config.sessionId, 'abc');
      expect(config.isChatCondition, isTrue);
    });

    test('reads the optional Prolific session and study ids', () {
      final config = SessionConfig.fromUri(
        Uri.parse(
          'http://localhost/?stim=36bde6&pid=A&sid=r1'
          '&psid=6ab26dc7a460741afcf6675b&study=6ab2699f6caa770baffa7d8c',
        ),
      );

      expect(config.prolificSessionId, '6ab26dc7a460741afcf6675b');
      expect(config.studyId, '6ab2699f6caa770baffa7d8c');
    });

    test('treats missing or empty optional ids as not provided', () {
      final missing = SessionConfig.fromUri(
        Uri.parse('http://localhost/?stim=36bde6&pid=A'),
      );
      expect(missing.prolificSessionId, isNull);
      expect(missing.studyId, isNull);

      final empty = SessionConfig.fromUri(
        Uri.parse('http://localhost/?stim=36bde6&pid=A&sid=&psid=&study='),
      );
      expect(empty.prolificSessionId, isNull);
      expect(empty.studyId, isNull);
      expect(empty.sessionId, startsWith('sess_'));
    });

    test('maps each stim code to its condition', () {
      Condition parse(String code) => SessionConfig.fromUri(
        Uri.parse('http://localhost/?stim=$code&pid=A'),
      ).condition;

      expect(parse('36bde6'), Condition.manual);
      expect(parse('fbd736'), Condition.chatDefault);
      expect(parse('64e213'), Condition.chatPrice);
      expect(parse(' 36BDE6 '), Condition.manual);
    });

    test('rejects the old readable param and unknown codes', () {
      for (final query in [
        'condition=manual',
        'stim=manual',
        'stim=000000',
        '',
      ]) {
        expect(
          () => SessionConfig.fromUri(
            Uri.parse('http://localhost/?$query&pid=A'),
          ),
          throwsA(isA<SessionConfigError>()),
          reason: query,
        );
      }
    });

    test('stim codes are pinned, distinct and $stimCodeLength chars', () {
      final codes = Condition.values.map((c) => c.stimCode).toList();
      expect(codes, ['36bde6', 'fbd736', '64e213']);
      expect(codes.toSet().length, codes.length);
    });
  });
}
