import 'package:flutter/material.dart';
import 'package:prism_ai/prism_ai.dart';
import 'package:prism_markdown/prism_markdown.dart';

import '../services/ai_service.dart';

/// Full-screen AI chat with streaming markdown responses.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.service});

  final AiService service;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = AiChatController();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.service.ensureInitialized();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _busy) return;
    _inputController.clear();
    setState(() => _busy = true);

    controller.sendUserMessage(text);

    try {
      await for (final event in widget.service.stream(text)) {
        switch (event) {
          case AiTextDelta(:final text):
            controller.appendAssistantDelta(text);
            _autoScroll();
          case AiToolCall(:final name):
            controller.appendAssistantDelta('\n🔧 $name\n');
          case AiDone():
            controller.finishAssistant();
          case AiError(:final message):
            controller.reportError(message);
        }
      }
    } catch (e) {
      controller.reportError(e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prism AI'),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final messages = controller.messages;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length +
                      (controller.isStreaming ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= messages.length) {
                      return const _TypingIndicator();
                    }
                    final msg = messages[i];
                    final isUser = msg.role == AiRole.user;

                    // Assistant messages render as markdown
                    if (!isUser && msg.content.isNotEmpty) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(14),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16)
                                .copyWith(bottomLeft: const Radius.circular(4)),
                          ),
                          child: PrismMarkdown(msg.content),
                        ),
                      );
                    }

                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: Radius.circular(isUser ? 4 : 16),
                            bottomLeft: Radius.circular(isUser ? 16 : 4),
                          ),
                        ),
                        child: SelectableText(
                          msg.content,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          decoration: InputDecoration(
                            hintText: 'Ask anything…',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: _send,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        child: IconButton(
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.send, size: 20),
                          onPressed: _busy ? null : () => _send(_inputController.text),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  AiChatController get controller => _controller;
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(3, (i) {
          return FadeTransition(
            opacity: Tween(begin: 0.2, end: 1.0).animate(CurvedAnimation(
              parent: _anim,
              curve: Interval(i * 0.2, i * 0.2 + 0.4, curve: Curves.easeInOut),
            )),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: CircleAvatar(
                radius: 4,
                backgroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }),
      ),
    );
  }
}
