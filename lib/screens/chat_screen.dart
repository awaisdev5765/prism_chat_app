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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(Icons.auto_awesome, size: 20, color: theme.colorScheme.onPrimary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prism AI', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  controller.isStreaming ? 'typing…' : 'online',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: controller.isStreaming
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final messages = controller.messages;
          return Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF121018)
                        : const Color(0xFFF8F7FC),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    itemCount: messages.length + (controller.isStreaming ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= messages.length) {
                        return const _TypingIndicator();
                      }
                      final msg = messages[i];
                      final isUser = msg.role == AiRole.user;
                      return _MessageBubble(
                        message: msg.content,
                        isUser: isUser,
                        theme: theme,
                        useMarkdown: !isUser,
                      );
                    },
                  ),
                ),
              ),
              _InputBar(
                controller: _inputController,
                onSend: _send,
                enabled: !_busy,
              ),
            ],
          );
        },
      ),
    );
  }

  AiChatController get controller => _controller;
}

// ---------------------------------------------------------------------------
// Message bubble
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.theme,
    this.useMarkdown = false,
  });

  final String message;
  final bool isUser;
  final ThemeData theme;
  final bool useMarkdown;

  @override
  Widget build(BuildContext context) {
    final gradient = isUser
        ? LinearGradient(colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ])
        : null;
    final bgColor = isUser
        ? null
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(isUser ? 16 : -16, 0),
              child: child,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.80,
          ),
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? bgColor : null,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: useMarkdown
              ? PrismMarkdown(
                  message,
                  style: PrismMarkdownStyle(
                    textStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      height: 1.5,
                    ),
                  ),
                )
              : SelectableText(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    height: 1.4,
                  ),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Typing indicator
// ---------------------------------------------------------------------------

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18)
                .copyWith(bottomLeft: const Radius.circular(4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return ScaleTransition(
                scale: Tween(begin: 0.6, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _anim,
                    curve: Interval(i * 0.25, i * 0.25 + 0.35,
                        curve: Curves.easeInOut),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: CircleAvatar(radius: 4.5, backgroundColor: color),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input bar
// ---------------------------------------------------------------------------

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  final TextEditingController controller;
  final void Function(String) onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: onSend,
                  decoration: InputDecoration(
                    hintText: 'Ask anything…',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: enabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    size: 22,
                    color: enabled
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
