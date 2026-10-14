import 'package:ai_research/app/experiment_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// Asset loading is real I/O that the test clock doesn't drive, so wait for
/// it explicitly; otherwise the loading spinner keeps `pumpAndSettle` from
/// ever settling.
Future<void> _pumpApp(WidgetTester tester, Uri uri) async {
  await tester.pumpWidget(ExperimentApp(uri: uri));
  for (var i = 0; i < 100; i++) {
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  // rootBundle caches load futures across tests; a future created inside an
  // earlier test's zone never completes for later ones.
  setUp(() => rootBundle.clear());

  testWidgets('renders the document reader for a valid manual-condition URL', (
    tester,
  ) async {
    final uri = Uri.parse(
      'https://example.com/?condition=manual&pid=TESTPID123',
    );

    await _pumpApp(tester, uri);

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.textContaining('This task link is missing'), findsNothing);
  });

  testWidgets('shows the chat placeholder for a valid chat-condition URL', (
    tester,
  ) async {
    final uri = Uri.parse(
      'https://example.com/?condition=chat_default&pid=TESTPID123',
    );

    await _pumpApp(tester, uri);

    expect(find.textContaining('Chat UI placeholder'), findsOneWidget);
  });

  testWidgets('shows an error screen when condition is missing', (
    tester,
  ) async {
    final uri = Uri.parse('https://example.com/?pid=TESTPID123');

    await _pumpApp(tester, uri);

    expect(find.textContaining('This task link is missing'), findsOneWidget);
  });

  testWidgets('shows an error screen when the Prolific ID is missing', (
    tester,
  ) async {
    final uri = Uri.parse('https://example.com/?condition=manual');

    await _pumpApp(tester, uri);

    expect(find.textContaining('This task link is missing'), findsOneWidget);
  });
}
