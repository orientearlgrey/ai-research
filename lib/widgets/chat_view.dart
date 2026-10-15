import 'package:flutter/material.dart';

import '../chat/chat_backend.dart';
import '../config/session_config.dart';
import '../models/chat_message.dart';
import 'markdown_content_view.dart';

/// Chat UI for the `chat_*` conditions. Assistant replies go through the same
/// [MarkdownContentView] as the document reader, so information looks the
/// same across conditions.
class ChatView extends StatefulWidget {
  final ChatBackend backend;
  final SessionConfig session;
  final String documentMarkdown;

  const ChatView({
    super.key,
    required this.backend,
    required this.session,
    required this.documentMarkdown,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  static const _userBubble = Color(0xFF3B5BDB);
  static const _assistantBubble = Color(0xFFF1F1F4);
  static const _genericError = 'Something went wrong. Please try again.';

  final _messages = <ChatMessage>[];
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _waiting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _waiting) return;

    final userMessage = ChatMessage(
      role: ChatRole.user,
      content: text,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(userMessage);
      _waiting = true;
      _error = null;
      _controller.clear();
    });
    _scrollToEnd();

    try {
      final reply = await widget.backend.sendMessage(
        ChatRequest(
          session: widget.session,
          history: List.unmodifiable(_messages),
          documentMarkdown: widget.documentMarkdown,
        ),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            role: ChatRole.assistant,
            content: reply,
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      // Drop the unanswered message and put the text back so the history
      // stays alternating and the participant can just resend.
      setState(() {
        _messages.remove(userMessage);
        if (_controller.text.isEmpty) _controller.text = text;
        _error = _genericError;
      });
    } finally {
      if (mounted) setState(() => _waiting = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && !_waiting
                ? const Center(
                    child: Text(
                      'Ask a question to get started.',
                      style: TextStyle(color: Colors.black45, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) => _Bubble(
                      message: _messages[i],
                      color: _messages[i].role == ChatRole.user
                          ? _userBubble
                          : _assistantBubble,
                    ),
                  ),
          ),
          if (_waiting)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Typing…',
                  style: TextStyle(color: Colors.black45, fontSize: 13),
                ),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFB3261E),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          _InputBar(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final Color color;

  const _Bubble({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.85),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: isUser
              ? Text(
                  message.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.35,
                  ),
                )
              : MarkdownContentView(data: message.content),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE6E6EA))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Message',
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF1F1F4),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Send',
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded, color: Color(0xFF3B5BDB)),
          ),
        ],
      ),
    );
  }
}
