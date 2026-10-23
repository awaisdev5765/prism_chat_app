import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prism_ai/prism_ai.dart';
import 'package:prism_markdown/prism_markdown.dart';

import '../services/ai_service.dart';
import 'settings_screen.dart';

const _suggestions = [
  ('Explain a concept', Icons.lightbulb_outline),
  ('Write code', Icons.code),
  ('Brainstorm ideas', Icons.psychology_outlined),
  ('Summarize text', Icons.summarize_outlined),
];

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
  final _focusNode = FocusNode();
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
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _busy) return;
    _inputController.clear();
    _focusNode.unfocus();
    HapticFeedback.lightImpact();
    setState(() => _busy = true);
    _controller.sendUserMessage(text);
    try {
      await for (final event in widget.service.stream(text)) {
        switch (event) {
          case AiTextDelta(:final text):
            _controller.appendAssistantDelta(text);
            _autoScroll();
          case AiDone():
            _controller.finishAssistant();
          case AiError(:final message):
            _controller.reportError(message);
          default:
            break;
        }
      }
    } catch (e) {
      _controller.reportError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
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

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Copied'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text('Prism AI'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_comment_outlined,
                color: isDark ? Colors.white70 : Colors.black54),
            onPressed: _controller.clear,
            tooltip: 'New chat',
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined,
                color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => SettingsScreen(service: widget.service))),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final messages = _controller.messages;
          return Column(
            children: [
              Expanded(
                child: messages.isEmpty && !_controller.isStreaming
                    ? _EmptyState(onTap: _send)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: messages.length +
                            (_controller.isStreaming ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i >= messages.length) {
                            return const _TypingIndicator();
                          }
                          final msg = messages[i];
                          final isUser = msg.role == AiRole.user;
                          return _MessageBubble(
                            message: msg.content,
                            isUser: isUser,
                            markdown: !isUser,
                            onCopy: () => _copy(msg.content),
                          );
                        },
                      ),
              ),
              _InputBar(
                controller: _inputController,
                focusNode: _focusNode,
                onSend: _send,
                enabled: !_busy,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTap});
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.auto_awesome, size: 30, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 20),
            Text('How can I help?',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            ..._suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onTap(s.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(s.$2, size: 18, color: isDark ? Colors.white60 : Colors.black45),
                          const SizedBox(width: 12),
                          Text(s.$1,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Icon(Icons.arrow_forward_ios, size: 12, color: isDark ? Colors.white24 : Colors.black26),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.markdown,
    required this.onCopy,
  });
  final String message;
  final bool isUser;
  final bool markdown;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.80),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF2563EB)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isUser)
              SelectableText(message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white, height: 1.45))
            else
              PrismMarkdown(
                message,
                style: PrismMarkdownStyle(
                  textStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : const Color(0xFF1A1A1A),
                    height: 1.55,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Just now',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: isUser
                        ? Colors.white.withValues(alpha: 0.6)
                        : (isDark ? Colors.white38 : Colors.black26),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onCopy,
                  child: Icon(
                    Icons.copy_outlined,
                    size: 14,
                    color: isUser
                        ? Colors.white.withValues(alpha: 0.6)
                        : (isDark ? Colors.white38 : Colors.black26),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return ScaleTransition(
              scale: Tween(begin: 0.5, end: 1.0).animate(CurvedAnimation(
                parent: _controller,
                curve: Interval(i * 0.25, i * 0.25 + 0.35, curve: Curves.easeInOut),
              )),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: CircleAvatar(radius: 4, backgroundColor: color),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.enabled,
    required this.focusNode,
  });
  final TextEditingController controller;
  final void Function(String) onSend;
  final bool enabled;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: onSend,
              decoration: InputDecoration(
                hintText: 'Message…',
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: enabled ? () => onSend(controller.text) : null,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0xFF2563EB)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.06)),
                borderRadius: BorderRadius.circular(19),
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 20,
                color: enabled
                    ? Colors.white
                    : (isDark ? Colors.white38 : Colors.black26),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
