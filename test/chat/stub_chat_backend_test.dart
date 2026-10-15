import 'dart:io';

import 'package:ai_research/chat/chat_backend.dart';
import 'package:ai_research/chat/stub_chat_backend.dart';
import 'package:ai_research/config/session_config.dart';
import 'package:ai_research/models/chat_message.dart';
import 'package:ai_research/models/document_content.dart';
import 'package:ai_research/utils/markdown_document_builder.dart';
import 'package:ai_research/utils/seeded_shuffle.dart';
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
  _realContentTests();
  const backend = StubChatBackend(delay: Duration.zero);

  test('answers from the section whose header matches the question', () async {
    final reply = await backend.sendMessage(_request('Tell me about Beta'));

    expect(reply, contains('**Beta Cream**'));
    expect(reply, contains('Beta intro.'));
    expect(reply, isNot(contains('Alpha')));
  });

  test('falls back to the first section and returns all of it', () async {
    final reply = await backend.sendMessage(_request('What is this?'));

    expect(reply, contains('**Alpha Balm**'));
    expect(reply, contains('Alpha detail.'));
    expect(reply, contains('Alpha extra.'));
    expect(reply, isNot(contains('Beta')));
  });

  test('copes with an empty document', () async {
    final reply = await backend.sendMessage(_request('Hi', document: ''));

    expect(reply, isNotEmpty);
  });
}

void _realContentTests() {
  test(
    'with the real content, a KAHI question returns all of KAHI only',
    () async {
      final content = DocumentContent.fromJsonString(
        File('assets/content/products.json').readAsStringSync(),
      );
      final kahi = content.products.firstWhere((p) => p.name.contains('KAHI'));
      final kahiBody = kahi.bodyMarkdown
          .trim()
          .split('\n')
          .skip(1)
          .join('\n')
          .trim();

      const questions = [
        'Tell me about KAHI',
        'Tell me more about KAHI Wrinkle Bounce Multi Balm.',
      ];
      // The answer must not depend on where the shuffle puts each product.
      for (final pid in ['676183cb707ba8182ab23541', 'A', 'B', 'C', 'D', 'E']) {
        final document = buildDocumentMarkdown(
          shuffledProducts(content.products, pid),
        );
        for (final question in questions) {
          final reply = await const StubChatBackend(
            delay: Duration.zero,
          ).sendMessage(_request(question, document: document));

          expect(reply, contains(kahiBody), reason: '$pid / $question');
          for (final other in content.products.where((p) => p != kahi)) {
            expect(
              reply,
              isNot(contains(other.name)),
              reason: '${other.name} leaked for $pid / $question',
            );
          }
        }
      }
    },
  );
}
