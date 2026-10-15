import 'package:ai_research/chat/chat_backend.dart';
import 'package:ai_research/chat/stub_chat_backend.dart';
import 'package:ai_research/config/session_config.dart';
import 'package:ai_research/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

const _document =
    '# Alpha Balm\n\nAlpha intro.\n\nAlpha detail.\n\nAlpha extra.'
    '\n\n---\n\n'
    '# Beta Cream\n\nBeta intro.\n\nBeta detail.';

ChatRequest _request(String question, {String document = _document}) {
  return ChatRequest(
    session: const SessionConfig(
      condition: Condition.chatDefault,
      prolificId: 'P',
      sessionId: 'S',
    ),
    history: [
      ChatMessage(
        role: ChatRole.user,
        content: question,
        timestamp: DateTime(2026),
      ),
    ],
    documentMarkdown: document,
  );
}

void main() {
  const backend = StubChatBackend(delay: Duration.zero);

  test('answers from the section whose header matches the question', () async {
    final reply = await backend.sendMessage(_request('Tell me about Beta'));

    expect(reply, contains('**Beta Cream**'));
    expect(reply, contains('Beta intro.'));
    expect(reply, isNot(contains('Alpha')));
  });

  test('falls back to the first section and keeps only two blocks', () async {
    final reply = await backend.sendMessage(_request('What is this?'));

    expect(reply, contains('**Alpha Balm**'));
    expect(reply, contains('Alpha detail.'));
    expect(reply, isNot(contains('Alpha extra.')));
  });

  test('copes with an empty document', () async {
    final reply = await backend.sendMessage(_request('Hi', document: ''));

    expect(reply, isNotEmpty);
  });
}
