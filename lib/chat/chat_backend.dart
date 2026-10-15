import '../config/session_config.dart';
import '../models/chat_message.dart';

/// Everything a backend needs to produce the assistant's next reply.
///
/// The backend (not the app) decides the system prompt from [session], so
/// the condition-specific instructions never reach the browser.
class ChatRequest {
  final SessionConfig session;

  /// The full conversation so far, ending with the participant's new message.
  final List<ChatMessage> history;

  /// The shuffled document the assistant is grounded in; the same text the
  /// manual condition shows on screen.
  final String documentMarkdown;

  const ChatRequest({
    required this.session,
    required this.history,
    required this.documentMarkdown,
  });
}

/// Thrown when a backend cannot produce a reply. The UI shows a generic
/// message to the participant; [message] is for logs and debugging.
class ChatBackendException implements Exception {
  final String message;
  const ChatBackendException(this.message);

  @override
  String toString() => 'ChatBackendException: $message';
}

/// The chat UI depends only on this interface, so the model provider can be
/// swapped (stub, Cloudflare Worker, anything else) without touching the UI.
abstract class ChatBackend {
  /// Returns the assistant's markdown reply, or throws [ChatBackendException].
  Future<String> sendMessage(ChatRequest request);
}
