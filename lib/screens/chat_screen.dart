import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _messages = <_ChatMessage>[
    _ChatMessage(
      text: 'سلام! من مربی هوش مصنوعی شما هستم. چطور می‌تونم کمکتون کنم؟',
      isBot: true,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isBot: false));
      _controller.clear();
      // Simulated AI response
      _messages.add(_ChatMessage(
        text: 'ممنون از سوالت! بذار برنامه تمرینی مناسب رو برات طراحی کنم.',
        isBot: true,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            // ─── Header ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppTheme.gutter),
              child: Row(
                children: [
                  const Icon(Icons.arrow_forward_ios, color: AppTheme.textPrimary, size: 20),
                  const Spacer(),
                  Text('مربی هوش مصنوعی', style: AppTheme.headlineMd),
                  const Spacer(),
                  const SizedBox(width: 20),
                ],
              ),
            ),
            const Divider(color: AppTheme.outline, height: 1),
            // ─── Messages ──────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppTheme.gutter),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _ChatBubble(message: msg);
                },
              ),
            ),
            // ─── Input ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(
                  top: BorderSide(color: AppTheme.outline, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: AppTheme.bodyMd,
                      decoration: InputDecoration(
                        hintText: 'پیام خود را بنویسید...',
                        hintStyle: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: AppTheme.surfaceHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary,
                      ),
                      child: const Icon(Icons.send, color: AppTheme.onPrimary, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isBot;
  _ChatMessage({required this.text, required this.isBot});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isBot ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isBot ? AppTheme.surface : AppTheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: message.isBot
              ? Border.all(color: AppTheme.outline, width: 1)
              : null,
        ),
        child: Text(
          message.text,
          style: AppTheme.bodyMd.copyWith(
            color: message.isBot ? AppTheme.textPrimary : AppTheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
