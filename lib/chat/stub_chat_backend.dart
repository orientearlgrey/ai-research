import '../models/chat_message.dart';
import 'chat_backend.dart';

/// Stand-in backend used until the real one exists. It makes no network
/// calls: it replies with the whole document section that best matches the
/// question, so the UI shows realistic content.
class StubChatBackend implements ChatBackend {
  final Duration delay;

  const StubChatBackend({this.delay = const Duration(milliseconds: 700)});

  @override
  Future<String> sendMessage(ChatRequest request) async {
    await Future<void>.delayed(delay);

    final question = request.history
        .lastWhere(
          (m) => m.role == ChatRole.user,
          orElse: () => ChatMessage(
            role: ChatRole.user,
            content: '',
            timestamp: DateTime.now(),
          ),
        )
        .content;

    final sections = request.documentMarkdown
        .split('\n\n---\n\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (sections.isEmpty) {
      return "I don't have any notes to look at.";
    }

    final section = _bestSection(sections, question);
    final lines = section.trim().split('\n');
    final name = lines.first.replaceFirst(RegExp(r'^#+\s*'), '');
    final body = lines.skip(1).join('\n').trim();

    return 'Here is what the notes say about **$name**:\n\n$body';
  }

  /// The section whose header shares the most words with [question] (the
  /// earliest wins a tie), else the first section.
  String _bestSection(List<String> sections, String question) {
    final words = question
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 3)
        .toSet();

    var best = sections.first;
    var bestScore = 0;
    for (final section in sections) {
      final header = section.split('\n').first.toLowerCase();
      final score = words.where(header.contains).length;
      if (score > bestScore) {
        best = section;
        bestScore = score;
      }
    }
    return best;
  }
}
