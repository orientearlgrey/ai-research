import 'package:ai_research/app/experiment_app.dart';
import 'package:ai_research/widgets/document_reader_view.dart';
import 'package:ai_research/widgets/phone_mockup_frame.dart';
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
    final uri = Uri.parse('https://example.com/?stim=36bde6&pid=TESTPID123');

    await _pumpApp(tester, uri);

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.textContaining('This task link is missing'), findsNothing);
  });

  testWidgets('shows the chat placeholder for a valid chat-condition URL', (
    tester,
  ) async {
    final uri = Uri.parse('https://example.com/?stim=fbd736&pid=TESTPID123');

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
    final uri = Uri.parse('https://example.com/?stim=36bde6');

    await _pumpApp(tester, uri);

    expect(find.textContaining('This task link is missing'), findsOneWidget);
  });

  testWidgets('does not overflow in a tall, narrow viewport', (tester) async {
    tester.view.physicalSize = const Size(700, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pumpApp(
      tester,
      Uri.parse('https://example.com/?stim=36bde6&pid=TESTPID123'),
    );

    expect(tester.takeException(), isNull);
    final phone = tester.getRect(find.byType(PhoneMockupFrame));
    expect(phone.right, lessThanOrEqualTo(700));
    // Shelf panel keeps a usable share of the width.
    expect(phone.left, greaterThanOrEqualTo(700 * 0.4));
  });

  testWidgets('zooms the phone content out by contentZoom', (tester) async {
    await _pumpApp(
      tester,
      Uri.parse('https://example.com/?stim=36bde6&pid=TESTPID123'),
    );

    final screenWidth = tester
        .getSize(
          find.descendant(
            of: find.byType(PhoneMockupFrame),
            matching: find.byType(ClipRRect),
          ),
        )
        .width;
    final contentWidth = tester.getSize(find.byType(DocumentReaderView)).width;

    expect(
      contentWidth,
      closeTo(screenWidth / PhoneMockupFrame.contentZoom, 1),
    );
  });
}
