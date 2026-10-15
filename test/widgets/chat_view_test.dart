import 'dart:async';

import 'package:ai_research/chat/chat_backend.dart';
import 'package:ai_research/config/session_config.dart';
import 'package:ai_research/models/chat_message.dart';
import 'package:ai_research/widgets/chat_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _session = SessionConfig(
  condition: Condition.chatDefault,
  prolificId: 'P',
  sessionId: 'S',
);

class _FakeBackend implements ChatBackend {
  final requests = <ChatRequest>[];
  Future<String> Function(ChatRequest request) onSend;

  _FakeBackend(this.onSend);

  @override
  Future<String> sendMessage(ChatRequest request) {
    requests.add(request);
    return onSend(request);
  }
}

Widget _wrap(ChatBackend backend) {
  return MaterialApp(
    home: Scaffold(
      body: ChatView(
        backend: backend,
        session: _session,
        documentMarkdown: 'DOC',
      ),
    ),
  );
}

Future<void> _send(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.byIcon(Icons.send_rounded));
  await tester.pump();
}

void main() {
  testWidgets('shows a hint before any message', (tester) async {
    await tester.pumpWidget(_wrap(_FakeBackend((_) async => 'unused')));

    expect(find.text("Hi. What's on your mind?"), findsOneWidget);
  });

  testWidgets('shows the question and the markdown reply', (tester) async {
    final backend = _FakeBackend((_) async => 'It is **great** for lips.');
    await tester.pumpWidget(_wrap(backend));

    await _send(tester, 'What is it good for?');
    await tester.pumpAndSettle();

    expect(find.text('What is it good for?'), findsOneWidget);
    expect(find.textContaining('great', findRichText: true), findsOneWidget);
    expect(find.textContaining('**', findRichText: true), findsNothing);
    expect(find.text("Hi. What's on your mind?"), findsNothing);
  });

  testWidgets('sends the full history, session and document', (tester) async {
    final backend = _FakeBackend((_) async => 'reply');
    await tester.pumpWidget(_wrap(backend));

    await _send(tester, 'first');
    await tester.pumpAndSettle();
    await _send(tester, 'second');
    await tester.pumpAndSettle();

    final second = backend.requests.last;
    expect(second.documentMarkdown, 'DOC');
    expect(second.session.prolificId, 'P');
    expect(second.history.map((m) => (m.role, m.content)), [
      (ChatRole.user, 'first'),
      (ChatRole.assistant, 'reply'),
      (ChatRole.user, 'second'),
    ]);
  });

  testWidgets('ignores blank input and a second send while waiting', (
    tester,
  ) async {
    final completer = Completer<String>();
    final backend = _FakeBackend((_) => completer.future);
    await tester.pumpWidget(_wrap(backend));

    await _send(tester, '   ');
    expect(backend.requests, isEmpty);

    await _send(tester, 'one');
    expect(find.text('Typing…'), findsOneWidget);
    await _send(tester, 'two');
    expect(backend.requests, hasLength(1));

    completer.complete('done');
    await tester.pumpAndSettle();
    expect(find.text('Typing…'), findsNothing);
  });

  testWidgets('on failure shows an error and restores the text', (
    tester,
  ) async {
    final backend = _FakeBackend(
      (_) async => throw const ChatBackendException('boom'),
    );
    await tester.pumpWidget(_wrap(backend));

    await _send(tester, 'hello');
    await tester.pumpAndSettle();

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('hello'), findsOneWidget); // back in the text field
    expect(find.byType(ListView), findsNothing); // unanswered message dropped

    backend.onSend = (_) async => 'ok now';
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('ok now', findRichText: true), findsOneWidget);
    expect(find.text('Something went wrong. Please try again.'), findsNothing);
  });

  testWidgets('keeps line breaks in a multiline message', (tester) async {
    final backend = _FakeBackend((_) async => 'ok');
    await tester.pumpWidget(_wrap(backend));

    await _send(tester, 'line one\nline two');
    await tester.pumpAndSettle();

    expect(
      backend.requests.single.history.single.content,
      'line one\nline two',
    );
    expect(find.text('line one\nline two'), findsOneWidget);
  });

  testWidgets('input grows to several lines', (tester) async {
    await tester.pumpWidget(_wrap(_FakeBackend((_) async => 'ok')));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 1);
    expect(field.maxLines, greaterThan(1));
    expect(field.keyboardType, TextInputType.multiline);
  });

  testWidgets('Enter sends but Shift+Enter does not', (tester) async {
    final backend = _FakeBackend((_) async => 'ok');
    await tester.pumpWidget(_wrap(backend));

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'hello');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(backend.requests, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(backend.requests, hasLength(1));
    expect(backend.requests.single.history.single.content, 'hello');
  });
}
