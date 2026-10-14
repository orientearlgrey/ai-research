import 'package:ai_research/config/session_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionConfig.fromUri', () {
    test('parses a real Prolific-style id and generates a fallback sid', () {
      final config = SessionConfig.fromUri(
        Uri.parse(
          'http://localhost/?condition=manual&pid=676183cb707ba8182ab23541',
        ),
      );

      expect(config.condition, Condition.manual);
      expect(config.prolificId, '676183cb707ba8182ab23541');
      expect(config.sessionId, startsWith('sess_'));
    });

    test('uses the sid query param when present', () {
      final config = SessionConfig.fromUri(
        Uri.parse('http://localhost/?condition=chat_price&pid=A&sid=abc'),
      );

      expect(config.sessionId, 'abc');
      expect(config.isChatCondition, isTrue);
    });
  });
}
