import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/physiqo_header.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../repositories/chat_repository.dart';
import '../l10n/translations.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late AnimationController _animationController;
  late ChatRepository _repository;
  bool _isLoading = true;
  bool? _isLtrChat;
  ChatSession? _activeSession;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _initRepository();
  }

  Future<void> _initRepository() async {
    final prefs = await SharedPreferences.getInstance();
    _repository = ChatRepository(prefs);
    _isLtrChat = prefs.getBool('chat_is_ltr');
    final sessions = _repository.getAllSessions();
    if (sessions.isEmpty) {
      final newSession = await _repository.createSession();
      setState(() {
        _activeSession = newSession;
        _isLoading = false;
      });
    } else {
      setState(() {
        _activeSession = sessions.first;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _activeSession == null) return;

    final userMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: ChatMessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );

    _controller.clear();
    
    if (_activeSession!.messages.isEmpty) {
      await _repository.saveNewSession(_activeSession!);
    }
    await _repository.addMessage(_activeSession!.id, userMsg);
    _refreshActiveSession();

    // Simulated AI response
    Future.delayed(const Duration(milliseconds: 300), () async {
      if (mounted && _activeSession != null) {
        final botMsg = ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          role: ChatMessageRole.coach,
          content: context.tr('chat_mock_reply'),
          timestamp: DateTime.now(),
        );
        await _repository.addMessage(_activeSession!.id, botMsg);
        _refreshActiveSession();
      }
    });
  }

  Future<void> _handleQuickAction(String userMsgText, String botReplyText) async {
    if (_activeSession == null) return;

    final userMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: ChatMessageRole.user,
      content: userMsgText,
      timestamp: DateTime.now(),
    );

    if (_activeSession!.messages.isEmpty) {
      await _repository.saveNewSession(_activeSession!);
    }
    await _repository.addMessage(_activeSession!.id, userMsg);
    _refreshActiveSession();

    Future.delayed(const Duration(milliseconds: 300), () async {
      if (mounted && _activeSession != null) {
        final botMsg = ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          role: ChatMessageRole.coach,
          content: botReplyText,
          timestamp: DateTime.now(),
        );
        await _repository.addMessage(_activeSession!.id, botMsg);
        _refreshActiveSession();
      }
    });
  }

  void _refreshActiveSession() {
    final sessions = _repository.getAllSessions();
    final updated = sessions.firstWhere((s) => s.id == _activeSession?.id, orElse: () => _activeSession!);
    setState(() {
      _activeSession = updated;
    });
  }

  Future<void> _startNewChat() async {
    if (_activeSession != null && _activeSession!.messages.isEmpty) {
      return;
    }
    final newSession = await _repository.createSession();
    setState(() {
      _activeSession = newSession;
    });
  }

  String _getRelativeTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return context.tr('chat_time_just_now');
    } else if (difference.inMinutes < 60) {
      return context.tr('chat_time_mins_ago').replaceFirst('{}', difference.inMinutes.toString());
    } else if (difference.inHours < 24) {
      return context.tr('chat_time_hours_ago').replaceFirst('{}', difference.inHours.toString());
    } else {
      return context.tr('chat_time_days_ago').replaceFirst('{}', difference.inDays.toString());
    }
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final sessions = _repository.getAllSessions();

            return Container(
              padding: const EdgeInsets.all(AppTheme.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.tr('chat_history'), style: AppTheme.headlineMd),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: AppTheme.outline),
                  Expanded(
                    child: ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final isSelected = session.id == _activeSession?.id;
                        final lastMsg = session.messages.isNotEmpty
                            ? session.messages.last.content
                            : context.tr('chat_no_messages');
                        final timeStr = _getRelativeTimestamp(session.updatedAt);

                        return _SessionRow(
                          session: session,
                          isSelected: isSelected,
                          lastMsgPreview: lastMsg,
                          timeStr: timeStr,
                          onSelect: () {
                            setState(() {
                              _activeSession = session;
                            });
                            Navigator.pop(context);
                          },
                          onRename: (newTitle) async {
                            await _repository.renameSession(session.id, newTitle);
                            setSheetState(() {});
                            setState(() {
                              if (_activeSession?.id == session.id) {
                                _activeSession = _activeSession?.copyWith(title: newTitle);
                              }
                            });
                          },
                          onDelete: () async {
                            await _repository.deleteSession(session.id);
                            setSheetState(() {});
                            final updated = _repository.getAllSessions();
                            setState(() {
                              if (updated.isNotEmpty) {
                                _activeSession = updated.first;
                              } else {
                                _activeSession = null;
                              }
                            });
                            if (_activeSession == null) {
                              _startNewChat();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    final messages = _activeSession?.messages ?? [];
    final showEmptyState = messages.isEmpty;
    final isLtr = _isLtrChat ?? (Directionality.of(context) == TextDirection.ltr);

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            PhysiqoHeader.back(title: context.tr('title_ai_coach')),
            const Divider(color: AppTheme.outline, height: 1),
            // Header control row (History & New Chat)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter, vertical: 4),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.outline, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // History button (RTL right side -> start of row)
                  IconButton(
                    icon: const Icon(Icons.history, color: AppTheme.textPrimary),
                    onPressed: _showHistorySheet,
                  ),
                  const Spacer(),
                  // New chat button (RTL left side -> end of row)
                  IconButton(
                    icon: const Icon(Icons.add_comment_outlined, color: AppTheme.primary),
                    onPressed: _startNewChat,
                  ),
                ],
              ),
            ),
            // Content Area & Input wrapped in Directionality
            Expanded(
              child: Directionality(
                textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
                child: Column(
                  children: [
                    Expanded(
                      child: showEmptyState
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(AppTheme.gutter),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                return _ChatBubble(
                                  message: msg,
                                  onEdit: () {},
                                  onDelete: () async {
                                    if (_activeSession != null) {
                                      await _repository.deleteMessage(_activeSession!.id, msg.id);
                                      _refreshActiveSession();
                                    }
                                  },
                                  onUpdateContent: (newContent) async {
                                    if (_activeSession != null) {
                                      await _repository.editMessage(_activeSession!.id, msg.id, newContent);
                                      _refreshActiveSession();
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                    // Input Bar
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingSm),
                      decoration: const BoxDecoration(
                        color: AppTheme.surface,
                        border: Border(
                          top: BorderSide(color: AppTheme.outline, width: 1),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              style: AppTheme.bodyMd,
                              minLines: 1,
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                              textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
                              decoration: InputDecoration(
                                hintText: context.tr('chat_write_message'),
                                hintStyle: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                                filled: true,
                                fillColor: AppTheme.surfaceHigh,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.swap_horiz, color: AppTheme.textSecondary),
                                  onPressed: () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    setState(() {
                                      _isLtrChat = !isLtr;
                                    });
                                    await prefs.setBool('chat_is_ltr', _isLtrChat!);
                                  },
                                ),
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
                              child: Icon(
                                Icons.send, 
                                color: AppTheme.onPrimary, 
                                size: 18,
                                textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Pulsing AI Avatar / Orb Visual
          SizedBox(
            width: 160,
            height: 160,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _AiOrbPainter(animationValue: _animationController.value),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // Greeting Message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              context.tr('chat_greeting'),
              style: AppTheme.bodyLg.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          // Three Horizontal Quick-Action Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
            child: Row(
              children: [
                _QuickActionChip(
                  label: context.tr('chat_quick_scan'),
                  onTap: () => _handleQuickAction(
                    context.tr('chat_quick_scan'),
                    context.tr('chat_prompt_scan'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                _QuickActionChip(
                  label: context.tr('chat_quick_plan'),
                  onTap: () => _handleQuickAction(
                    context.tr('chat_quick_plan'),
                    context.tr('chat_prompt_plan'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                _QuickActionChip(
                  label: context.tr('chat_quick_move'),
                  onTap: () => _handleQuickAction(
                    context.tr('chat_quick_move'),
                    context.tr('chat_prompt_form'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Text(
          label,
          style: AppTheme.bodyMd.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String) onUpdateContent;

  const _ChatBubble({
    required this.message,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdateContent,
  });

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble> {
  bool _showActions = false;
  bool _isEditing = false;
  bool _showConfirmDelete = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCoach = widget.message.role == ChatMessageRole.coach;

    return Align(
      alignment: isCoach ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isCoach ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onLongPress: () {
              if (!isCoach) {
                setState(() {
                  _showActions = !_showActions;
                  _showConfirmDelete = false;
                  _isEditing = false;
                });
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isCoach
                    ? AppTheme.surface
                    : AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: isCoach
                    ? Border.all(color: AppTheme.outline, width: 1)
                    : Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1),
              ),
              child: _isEditing
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _editController,
                          style: AppTheme.bodyMd,
                          maxLines: null,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  _editController.text = widget.message.content;
                                });
                              },
                              child: Text(context.tr('chat_action_cancel'), style: TextStyle(color: AppTheme.textSecondary)),
                            ),
                            TextButton(
                              onPressed: () {
                                final text = _editController.text.trim();
                                if (text.isNotEmpty) {
                                  widget.onUpdateContent(text);
                                }
                                setState(() {
                                  _isEditing = false;
                                  _showActions = false;
                                });
                              },
                              child: Text(context.tr('chat_action_submit'), style: TextStyle(color: AppTheme.primary)),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.message.content,
                          style: AppTheme.bodyMd.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (widget.message.isEdited) ...[
                          const SizedBox(height: 4),
                          Text(
                            context.tr('chat_edited'),
                            style: AppTheme.labelMd.copyWith(
                              color: AppTheme.textSecondary.withValues(alpha: 0.7),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          if (_showActions && !isCoach && !_isEditing && !_showConfirmDelete)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: AppTheme.textSecondary),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16, color: AppTheme.error),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    onPressed: () {
                      setState(() {
                        _showConfirmDelete = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          if (_showConfirmDelete && !_isEditing)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.tr('chat_delete_confirm'), style: AppTheme.labelMd.copyWith(color: AppTheme.error)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: Text(context.tr('chat_yes'), style: AppTheme.labelMd.copyWith(color: AppTheme.error, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showConfirmDelete = false;
                          _showActions = false;
                        });
                      },
                      child: Text(context.tr('chat_no'), style: AppTheme.labelMd.copyWith(color: AppTheme.textPrimary)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatefulWidget {
  final ChatSession session;
  final bool isSelected;
  final String lastMsgPreview;
  final String timeStr;
  final VoidCallback onSelect;
  final Function(String) onRename;
  final VoidCallback onDelete;

  const _SessionRow({
    required this.session,
    required this.isSelected,
    required this.lastMsgPreview,
    required this.timeStr,
    required this.onSelect,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<_SessionRow> createState() => _SessionRowState();
}

class _SessionRowState extends State<_SessionRow> {
  bool _isRenaming = false;
  bool _showConfirmDelete = false;
  late TextEditingController _renameController;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController(text: widget.session.title);
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: widget.isSelected ? AppTheme.surfaceHigh : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: widget.isSelected ? AppTheme.primary : AppTheme.outline,
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: _isRenaming || _showConfirmDelete ? null : widget.onSelect,
        title: _isRenaming
            ? Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _renameController,
                      style: AppTheme.bodyMd,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                      ),
                      autofocus: true,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: AppTheme.primary, size: 18),
                    onPressed: () {
                      final val = _renameController.text.trim();
                      if (val.isNotEmpty) {
                        widget.onRename(val);
                      }
                      setState(() {
                        _isRenaming = false;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
                    onPressed: () {
                      setState(() {
                        _isRenaming = false;
                        _renameController.text = widget.session.title;
                      });
                    },
                  ),
                ],
              )
            : Text(
                widget.session.title,
                style: AppTheme.bodyLg.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.isSelected ? AppTheme.primary : AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        subtitle: _showConfirmDelete
            ? Row(
                children: [
                  Text(context.tr('chat_delete_confirm'), style: AppTheme.labelMd.copyWith(color: AppTheme.error)),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onDelete,
                    child: Text(context.tr('yes'), style: AppTheme.labelMd.copyWith(color: AppTheme.error, fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showConfirmDelete = false;
                      });
                    },
                    child: Text(context.tr('no'), style: AppTheme.labelMd.copyWith(color: AppTheme.textPrimary)),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.lastMsgPreview,
                      style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.timeStr,
                    style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary, fontSize: 10),
                  ),
                ],
              ),
        trailing: _isRenaming || _showConfirmDelete
            ? null
            : PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                color: AppTheme.surfaceHigh,
                onSelected: (val) {
                  if (val == 'rename') {
                    setState(() {
                      _isRenaming = true;
                    });
                  } else if (val == 'delete') {
                    setState(() {
                      _showConfirmDelete = true;
                    });
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'rename',
                    child: Text(context.tr('chat_rename'), style: const TextStyle(color: AppTheme.textPrimary)),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(context.tr('chat_delete_chat'), style: const TextStyle(color: AppTheme.error)),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AiOrbPainter extends CustomPainter {
  final double animationValue;

  _AiOrbPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final whitePaint = Paint()
      ..color = AppTheme.textPrimary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 16;

    // Draw central inner flat background
    canvas.drawCircle(Offset(cx, cy), radius - 12, whitePaint..color = AppTheme.surfaceHigh..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx, cy), radius - 12, whitePaint..color = AppTheme.textSecondary.withValues(alpha: 0.3)..style = PaintingStyle.stroke);

    // Inner flat sine wave
    final path = Path();
    path.moveTo(cx - 24, cy);
    for (double x = -24; x <= 24; x += 1) {
      final y = math.sin((x + animationValue * 360) * math.pi / 24) * 8 * math.sin(animationValue * math.pi);
      path.lineTo(cx + x, cy + y);
    }
    canvas.drawPath(path, Paint()..color = AppTheme.primary..strokeWidth = 2.0..style = PaintingStyle.stroke);

    // Outer dense radial spikes
    final numSpikes = 80;
    for (int i = 0; i < numSpikes; i++) {
      final angle = (i * 2 * math.pi) / numSpikes + (animationValue * 2 * math.pi * 0.1);
      final wave = math.sin(angle * 4 + animationValue * 2 * math.pi) * 0.5 + 0.5;
      final spikeHeight = 4 + wave * 16;

      final startX = cx + radius * math.cos(angle);
      final startY = cy + radius * math.sin(angle);
      final endX = cx + (radius + spikeHeight) * math.cos(angle);
      final endY = cy + (radius + spikeHeight) * math.sin(angle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AiOrbPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
