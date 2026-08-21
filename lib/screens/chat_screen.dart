import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/physiqo_header.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/ai_stream_event.dart';
import '../repositories/chat_repository.dart';
import '../l10n/translations.dart';
import '../services/ai_service.dart';
import '../services/ai_tools.dart';
import '../services/ai_orchestrator.dart';
import '../services/ai_logger.dart';
import '../widgets/ai_debug_dialog.dart';
import '../utils/farsi_formatter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late AnimationController _animationController;
  late ChatRepository _repository;
  final AiService _aiService = AiService();
  bool _isGenerating = false;
  bool _isLoading = true;
  StreamSubscription<AiStreamEvent>? _streamSubscription;
  Completer<void>? _streamCompleter;
  bool _generationCancelled = false;
  bool? _isLtrChat;
  ChatSession? _activeSession;
  final List<String> _selectedImages = [];
  final _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  bool _isCheckingOverride = false;
  bool _autoScrollEnabled = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final isAtBottom = _scrollController.offset <= 60.0;
        
        if (isAtBottom) {
          _autoScrollEnabled = true;
        } else {
          _autoScrollEnabled = false;
        }

        setState(() {
          _showScrollToBottom = _scrollController.offset > 150;
        });
      }
    });

    _initRepository();
  }

  Future<void> _initRepository() async {
    final prefs = await SharedPreferences.getInstance();
    _repository = ChatRepository(prefs);
    _isLtrChat = prefs.getBool('chat_is_ltr');
    final sessions = _repository.getAllSessions();
    
    if (sessions.isEmpty) {
      final newSession = await _repository.createSession();
      AiLogger.instance.setActiveChat(newSession.id);
      setState(() {
        _activeSession = newSession;
        _isLoading = false;
      });
    } else {
      AiLogger.instance.setActiveChat(sessions.first.id);
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
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((img) => img.path));
      });
    }
  }

  void _cancelOngoingMessage() {
    if (_generationCancelled) return;
    setState(() {
      _generationCancelled = true;
      _isGenerating = false;
    });
    _streamSubscription?.cancel();
    _streamSubscription = null;
    if (_streamCompleter != null && !_streamCompleter!.isCompleted) {
      _streamCompleter!.complete();
    }
    _refreshActiveSession();
  }

  Future<void> _retryMessage(ChatMessage systemErrorMsg) async {
    if (_activeSession == null || _isGenerating) return;
    
    // Delete the system error message from session
    await _repository.deleteMessage(_activeSession!.id, systemErrorMsg.id);
    _refreshActiveSession();
    
    // Find the last user message
    final lastUserMsg = _activeSession!.messages.lastWhere(
      (m) => m.role == ChatMessageRole.user,
      orElse: () => ChatMessage(id: '', role: ChatMessageRole.user, content: '', timestamp: DateTime.now()),
    );
    
    if (lastUserMsg.content.isNotEmpty) {
      setState(() {
        _isGenerating = true;
        _generationCancelled = false;
      });
      _refreshActiveSession();
      await _processAiLoop();
    }
  }

  String _getFriendlyErrorMessage(dynamic error, BuildContext context) {
    final errStr = error.toString();
    final isFa = Localizations.localeOf(context).languageCode == 'fa';
    
    if (errStr.contains('HandshakeException') || errStr.contains('cert') || errStr.contains('handshake') || errStr.contains('413')) {
      return isFa 
          ? 'خطای امنیتی یا بارگذاری شبکه (TLS/SSL/413).\nاین خطا معمولاً به دلیل محدودیت‌های شدید اینترنتی یا قطع اتصال فیلترشکن (VPN) رخ می‌دهد. لطفاً وضعیت فیلترشکن خود را بررسی کرده یا آن را تغییر دهید و مجدداً تلاش کنید.'
          : 'Network Security/Payload Error (TLS/SSL Handshake or 413 failed).\nThis is typically caused by local internet restrictions or an unstable VPN connection. Please check or switch your VPN and try again.';
    } else if (errStr.contains('SocketException') || errStr.contains('Failed host lookup') || errStr.contains('Connection refused') || errStr.contains('ClientException')) {
      return isFa
          ? 'خطا در ارتباط با سرور.\nامکان برقراری ارتباط با سرور هوش مصنوعی وجود ندارد. لطفاً مطمئن شوید که اتصال اینترنت شما برقرار است و فیلترشکن (VPN) متصل و فعال است.'
          : 'Server Connection Failed.\nUnable to reach the AI server. Please ensure your internet connection is active and your VPN is turned on.';
    } else if (errStr.contains('TimeoutException') || errStr.contains('timed out')) {
      return isFa
          ? 'پایان زمان پاسخ‌گویی سرور.\nارتباط با سرور به دلیل سرعت پایین اینترنت برقرار نشد. لطفاً مجدداً تلاش کنید.'
          : 'Request Timed Out.\nThe connection to the server timed out. Please try again.';
    }
    
    return isFa 
        ? '${context.tr('chat_network_error')}\n\n$errStr'
        : 'Connection failed.\n\n$errStr';
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if ((text.isEmpty && _selectedImages.isEmpty) || _activeSession == null || _isGenerating) return;

    _generationCancelled = false;
    final images = _selectedImages.isNotEmpty ? List<String>.from(_selectedImages) : null;
    final userMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: ChatMessageRole.user,
      content: text,
      timestamp: DateTime.now(),
      images: images,
    );

    _controller.clear();
    setState(() {
      _selectedImages.clear();
    });
    
    if (_activeSession!.messages.isEmpty) {
      await _repository.saveNewSession(_activeSession!);
    }
    await _repository.addMessage(_activeSession!.id, userMsg);
    
    setState(() {
      _isGenerating = true;
      _autoScrollEnabled = true;
    });
    _refreshActiveSession();
    
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    
    await _processAiLoop();
  }

  Future<void> _processAiLoop() async {
    if (!mounted || _activeSession == null) return;

    final orchestrator = AiOrchestrator();
    final lastUserMsg = _activeSession!.messages.lastWhere(
      (m) => m.role == ChatMessageRole.user, 
      orElse: () => ChatMessage(id: '', role: ChatMessageRole.user, content: '', timestamp: DateTime.now())
    );
    final language = orchestrator.detectLanguage(lastUserMsg.content);
    
    AiLogger.instance.clearTimeline();

    int loopCount = 0;
    while (true) {
      if (!mounted || _activeSession == null || _generationCancelled) break;
      loopCount++;
      if (loopCount > 8) {
        debugPrint('⚠️ Runaway tool calling detected. Breaking loop.');
        break;
      }

      try {
        AiLogger.instance.startTraceStep('Assemble Prompt & Tools');
        final contextData = await orchestrator.buildOrchestratedContext(language);
        if (_generationCancelled || !mounted) break;
        
        final systemPrompt = '''
${contextData['systemPrompt']}

## User Context (Current State)
${contextData['userContext']}
''';
        final tools = contextData['tools'] as List<Map<String, dynamic>>;
        AiLogger.instance.completeTraceStep(
          details: 'Prompt: ${systemPrompt.length} chars, Tools: ${tools.length}'
        );

        List<ChatMessage> historyToKeep = [];
        final allMessages = _activeSession!.messages;
        int lastUserIdx = allMessages.lastIndexWhere((m) => m.role == ChatMessageRole.user);
        
        if (lastUserIdx != -1) {
          final currentTurn = allMessages.sublist(lastUserIdx);
          final historyBefore = allMessages.sublist(0, lastUserIdx);
          
          int historyCount = 8;
          if (historyBefore.length > historyCount) {
            int sliceIdx = historyBefore.length - historyCount;
            while (sliceIdx < historyBefore.length && 
                   historyBefore[sliceIdx].role == ChatMessageRole.tool) {
              sliceIdx++;
            }
            historyToKeep.addAll(historyBefore.sublist(sliceIdx));
          } else {
            historyToKeep.addAll(historyBefore);
          }
          historyToKeep.addAll(currentTurn);
        } else {
          if (allMessages.length > 10) {
            historyToKeep = allMessages.sublist(allMessages.length - 10);
          } else {
            historyToKeep = List.from(allMessages);
          }
        }

        AiLogger.instance.startTraceStep('LLM Stream Request', details: 'Waiting for stream...');
        final rawStream = _aiService.sendMessageStream(
          historyToKeep,
          systemPrompt: systemPrompt,
          toolsOverride: loopCount >= 7 ? [] : tools,
          chatId: _activeSession!.id,
        );
        final stream = rawStream;
        if (_generationCancelled || !mounted) break;
        
        ChatMessage streamingMsg = ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          role: ChatMessageRole.coach,
          content: '',
          timestamp: DateTime.now(),
        );

        setState(() {
          _activeSession = _activeSession!.copyWith(
            messages: List.from(_activeSession!.messages)..add(streamingMsg),
          );
        });

        List<AiToolCall>? finalToolCalls;
        String finalContent = '';

        _streamCompleter = Completer<void>();
        _streamSubscription = stream.listen(
          (event) {
            if (!mounted || _activeSession == null || _generationCancelled) return;
            
            if (event.deltaText.isNotEmpty) {
              // Once we receive actual content delta, transition trace step
              if (AiLogger.instance.getActiveTimeline().last.name == 'LLM Stream Request') {
                AiLogger.instance.completeTraceStep(details: 'First token received');
                AiLogger.instance.startTraceStep('Receiving Content Stream');
              }

              finalContent = event.deltaText;
              setState(() {
                final index = _activeSession!.messages.indexWhere((m) => m.id == streamingMsg.id);
                if (index != -1) {
                  final msgs = List<ChatMessage>.from(_activeSession!.messages);
                  msgs[index] = streamingMsg.copyWith(content: finalContent, providerServed: event.providerServed);
                  _activeSession = _activeSession!.copyWith(messages: msgs);
                }
              });
              
              if (_autoScrollEnabled) {
                _scrollToBottom();
              }
            }
            
            if (event.isDone) {
              finalToolCalls = event.toolCalls;
              AiLogger.instance.completeTraceStep(
                details: 'Stream done. Length: ${finalContent.length} chars, Tool Calls: ${finalToolCalls?.length ?? 0}'
              );
            }
          },
          onError: (e) {
            if (_streamCompleter != null && !_streamCompleter!.isCompleted) {
              _streamCompleter!.completeError(e);
            }
          },
          onDone: () {
            if (_streamCompleter != null && !_streamCompleter!.isCompleted) {
              _streamCompleter!.complete();
            }
          },
          cancelOnError: true,
        );

        try {
          await _streamCompleter!.future;
        } catch (e) {
          if (!_generationCancelled) rethrow;
        } finally {
          _streamSubscription = null;
          _streamCompleter = null;
        }

        if (_generationCancelled || !mounted) break;
        
        if (mounted && _activeSession != null) {
          if (finalContent.isNotEmpty) {
            final completedMsg = _activeSession!.messages.firstWhere((m) => m.id == streamingMsg.id, orElse: () => streamingMsg).copyWith(content: finalContent);
            await _repository.addMessage(_activeSession!.id, completedMsg);
          } else {
            final msgs = List<ChatMessage>.from(_activeSession!.messages);
            msgs.removeWhere((m) => m.id == streamingMsg.id);
            _activeSession = _activeSession!.copyWith(messages: msgs);
          }
          _refreshActiveSession();
          
          if (_generationCancelled || !mounted) break;

          final toolCalls = finalToolCalls;
          if (toolCalls != null && toolCalls.isNotEmpty) {
            // First, add all initial tool messages sequentially to avoid DB race conditions
            final toolMsgs = <ChatMessage>[];
            for (var call in toolCalls) {
              final assistantMsg = ChatMessage(
                id: DateTime.now().microsecondsSinceEpoch.toString() + '_ast_' + call.id,
                role: ChatMessageRole.coach,
                content: '',
                toolCallId: call.id,
                toolName: call.name,
                toolArgs: jsonEncode(call.arguments),
                timestamp: DateTime.now(),
              );
              await _repository.addMessage(_activeSession!.id, assistantMsg);

              final toolMsg = ChatMessage(
                id: DateTime.now().microsecondsSinceEpoch.toString() + '_tool_' + call.id,
                role: ChatMessageRole.tool,
                content: '',
                toolCallId: call.id,
                toolName: call.name,
                toolArgs: jsonEncode(call.arguments),
                timestamp: DateTime.now(),
              );
              toolMsgs.add(toolMsg);
              await _repository.addMessage(_activeSession!.id, toolMsg);
            }
            _refreshActiveSession();

            if (_generationCancelled || !mounted) break;

            AiLogger.instance.startTraceStep(
              'Executing Tools', 
              details: 'Running: ${toolCalls.map((c) => c.name).join(", ")}'
            );

            // Execute all tools concurrently
            final futures = toolCalls.asMap().entries.map((entry) async {
              final index = entry.key;
              final call = entry.value;
              final result = await AiTools.executeTool(context, call.name, call.arguments);
              return {'index': index, 'result': result};
            }).toList();

            // Wait for all to finish
            final results = await Future.wait(futures);
            AiLogger.instance.completeTraceStep(
              details: 'Executed ${results.length} tools successfully'
            );

            if (_generationCancelled || !mounted) break;

            // Update all messages sequentially in DB
            for (var res in results) {
              final index = res['index'] as int;
              final result = res['result'] as String;
              final toolMsg = toolMsgs[index];
              
              if (result.startsWith('ACTION_NAVIGATE:')) {
                 final screen = result.split(':')[1];
                 if (screen == 'home' || screen == 'moves' || screen == 'body' || screen == 'settings' || screen == 'chat') {
                   if (mounted) {
                     Navigator.pushReplacementNamed(context, '/main', arguments: screen);
                   }
                 } else if (screen == 'analysis' || screen == 'schedule_overview' || screen == 'onboarding') {
                   if (mounted) {
                     Navigator.pushNamed(context, '/$screen');
                   }
                 }
              }

              final updatedToolMsg = toolMsg.copyWith(content: result);
              await _repository.updateMessage(_activeSession!.id, updatedToolMsg);
            }
            _refreshActiveSession();
          } else {
            break;
          }
        }
      } catch (e) {
        if (mounted && _activeSession != null && !_generationCancelled) {
          debugPrint('AiLoop Error: $e');
          final botMsg = ChatMessage(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            role: ChatMessageRole.system,
            content: _getFriendlyErrorMessage(e, context),
            timestamp: DateTime.now(),
          );
          await _repository.addMessage(_activeSession!.id, botMsg);
        }
        break;
      }
    }
    
    if (mounted) {
      setState(() {
        _isGenerating = false;
      });
      _refreshActiveSession();
    }
  }

  Future<void> _handleQuickAction(String userMsgText, {bool isEdited = false, List<String>? images}) async {
    if (_activeSession == null || _isGenerating) return;

    _generationCancelled = false;
    final userMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: ChatMessageRole.user,
      content: userMsgText,
      timestamp: DateTime.now(),
      isEdited: isEdited,
      images: images,
    );

    if (_activeSession!.messages.isEmpty) {
      await _repository.saveNewSession(_activeSession!);
    }
    await _repository.addMessage(_activeSession!.id, userMsg);
    
    setState(() {
      _isGenerating = true;
    });
    _refreshActiveSession();
    
    await _processAiLoop();
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
    AiLogger.instance.setActiveChat(newSession.id);
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
                            AiLogger.instance.setActiveChat(session.id);
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
                                AiLogger.instance.setActiveChat(_activeSession!.id);
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

  Future<void> _checkSessionOverride() async {
    if (_isCheckingOverride) return;
    _isCheckingOverride = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final overrideId = prefs.getString('active_session_id_override');
      if (overrideId != null) {
        await prefs.remove('active_session_id_override');
        
        final sessions = _repository.getAllSessions();
        final targetSession = sessions.firstWhere(
          (s) => s.id == overrideId, 
          orElse: () => _activeSession ?? sessions.first,
        );
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          AiLogger.instance.setActiveChat(targetSession.id);
          setState(() {
            _activeSession = targetSession;
          });
          
          if (targetSession.messages.isNotEmpty && 
              targetSession.messages.last.role == ChatMessageRole.user && 
              !_isGenerating) {
            setState(() {
              _isGenerating = true;
            });
            _processAiLoop();
          }
        });
      }
    } catch (e) {
      debugPrint('Error handling session override: $e');
    } finally {
      _isCheckingOverride = false;
    }
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

    _checkSessionOverride();

    final allMessages = _activeSession?.messages ?? [];
    final messages = allMessages.where((msg) {
      if (msg.role == ChatMessageRole.coach && msg.content.isEmpty) return false;
      if (msg.role == ChatMessageRole.tool && msg.content.isEmpty) {
        final isLast = allMessages.isNotEmpty && allMessages.last.id == msg.id;
        if (!_isGenerating || !isLast) return false;
      }
      return true;
    }).toList();
    final showEmptyState = messages.isEmpty && !_isGenerating;
    final isLtr = _isLtrChat ?? (Directionality.of(context) == TextDirection.ltr);
    final displayMessages = messages.reversed.toList();
    
    final List<dynamic> displayItems = [];
    List<ChatMessage> currentToolGroup = [];
    
    for (var msg in displayMessages) {
      if (msg.role == ChatMessageRole.tool) {
        currentToolGroup.add(msg);
      } else {
        if (currentToolGroup.isNotEmpty) {
          displayItems.add(currentToolGroup);
          currentToolGroup = [];
        }
        displayItems.add(msg);
      }
    }
    if (currentToolGroup.isNotEmpty) {
      displayItems.add(currentToolGroup);
    }

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
                  GestureDetector(
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AiDebugDialog(),
                      );
                    },
                    child: IconButton(
                      icon: const Icon(Icons.history, color: AppTheme.textPrimary),
                      onPressed: _showHistorySheet,
                    ),
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
                          : Stack(
                              children: [
                                ListView.builder(
                                  controller: _scrollController,
                                  reverse: true,
                                  physics: const ClampingScrollPhysics(),
                                  padding: const EdgeInsets.only(
                                    left: AppTheme.gutter,
                                    right: AppTheme.gutter,
                                    top: AppTheme.gutter,
                                    bottom: AppTheme.gutter * 2,
                                  ),
                                  itemCount: displayItems.length + (_isGenerating ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (_isGenerating && index == 0) {
                                      return const _TypingIndicatorBubble();
                                    }
                                    final item = displayItems[_isGenerating ? index - 1 : index];
                                    
                                    if (item is List<ChatMessage>) {
                                      return _ToolGroupBubble(tools: item);
                                    }
                                    
                                    final msg = item as ChatMessage;
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
                                          final idx = _activeSession!.messages.indexWhere((m) => m.id == msg.id);
                                          if (idx != -1) {
                                            final toRemove = _activeSession!.messages.sublist(idx).toList();
                                            for (var m in toRemove) {
                                              await _repository.deleteMessage(_activeSession!.id, m.id);
                                            }
                                            _refreshActiveSession();
                                            await _handleQuickAction(newContent, isEdited: true);
                                          }
                                        }
                                      },
                                      onOptionSelected: (selectedOption) {
                                        _controller.text = selectedOption;
                                        _sendMessage();
                                      },
                                      onRetry: msg.role == ChatMessageRole.system ? () => _retryMessage(msg) : null,
                                    );
                                  },
                                ),
                                if (_showScrollToBottom)
                                  Positioned(
                                    bottom: AppTheme.spacingMd,
                                    right: isLtr ? AppTheme.spacingMd : null,
                                    left: isLtr ? null : AppTheme.spacingMd,
                                    child: FloatingActionButton(
                                      mini: true,
                                      backgroundColor: AppTheme.surfaceHigh,
                                      foregroundColor: AppTheme.primary,
                                      onPressed: () {
                                        _autoScrollEnabled = true;
                                        _scrollToBottom();
                                      },
                                      child: const Icon(Icons.keyboard_arrow_down),
                                    ),
                                  ),
                              ],
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedImages.isNotEmpty)
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(right: 8, top: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                          border: Border.all(color: AppTheme.outline),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                          child: Image.file(
                                            File(_selectedImages[index]),
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedImages.removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: AppTheme.surfaceHigh,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, size: 14, color: AppTheme.textPrimary),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          if (_selectedImages.isNotEmpty) const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primary),
                                onPressed: _pickImages,
                              ),
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
                                  onSubmitted: _isGenerating ? null : (_) => _sendMessage(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _isGenerating ? _cancelOngoingMessage : _sendMessage,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isGenerating ? AppTheme.error : AppTheme.primary,
                                  ),
                                  child: Icon(
                                    _isGenerating ? Icons.stop : Icons.send, 
                                    color: AppTheme.onPrimary, 
                                    size: 18,
                                    textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
                                  ),
                                ),
                              ),
                            ],
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
                    context.tr('chat_prompt_scan'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                _QuickActionChip(
                  label: context.tr('chat_quick_plan'),
                  onTap: () => _handleQuickAction(
                    context.tr('chat_prompt_plan'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                _QuickActionChip(
                  label: context.tr('chat_quick_move'),
                  onTap: () => _handleQuickAction(
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
  final Function(String)? onOptionSelected;
  final VoidCallback? onRetry;

  const _ChatBubble({
    required this.message,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdateContent,
    this.onOptionSelected,
    this.onRetry,
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

  void _showImageFullScreen(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(File(imagePath)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.role == ChatMessageRole.tool) {
      return const SizedBox.shrink();
    }

    if (widget.message.role == ChatMessageRole.system) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, size: 18, color: AppTheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.message.content,
                    style: AppTheme.labelMd.copyWith(color: AppTheme.error),
                  ),
                ),
              ],
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh, size: 16, color: AppTheme.primary),
                  label: Text(
                    'تلاش مجدد / Try Again',
                    style: AppTheme.labelMd.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final isCoach = widget.message.role == ChatMessageRole.coach;
    
    String displayContent = FarsiFormatter.format(widget.message.content);
    List<String> parsedOptions = [];

    final optionsMatch = RegExp(r'<options>(.*?)</options>', dotAll: true).firstMatch(displayContent);
    if (optionsMatch != null) {
      displayContent = displayContent.replaceFirst(optionsMatch.group(0)!, '').trim();
      try {
        final List<dynamic> jsonArr = jsonDecode(optionsMatch.group(1)!);
        parsedOptions = jsonArr.map((e) => e.toString()).toList();
      } catch (e) {
        // ignore parse errors
      }
    }

    return Align(
      alignment: isCoach ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isCoach ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onLongPress: () {
              if (!isCoach && !widget.message.isEdited) {
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
                        if (widget.message.images != null && widget.message.images!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.message.images!.map((path) {
                                return GestureDetector(
                                  onTap: () => _showImageFullScreen(context, path),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    child: Image.file(
                                      File(path),
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        MarkdownBody(
                          data: displayContent,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: AppTheme.bodyMd.copyWith(color: AppTheme.textPrimary),
                            h1: AppTheme.headlineLg.copyWith(color: AppTheme.textPrimary),
                            h2: AppTheme.headlineMd.copyWith(color: AppTheme.textPrimary),
                            h3: AppTheme.bodyLg.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                            listBullet: AppTheme.bodyMd.copyWith(color: AppTheme.textPrimary),
                            code: AppTheme.labelMd.copyWith(
                              color: AppTheme.primary,
                              backgroundColor: AppTheme.surfaceHigh,
                              fontFamily: 'monospace',
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: AppTheme.surfaceHigh,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            blockquoteDecoration: BoxDecoration(
                              color: AppTheme.surfaceHigh,
                              border: const Border(
                                left: BorderSide(color: AppTheme.primary, width: 4),
                              ),
                            ),
                          ),
                        ),
                        if (parsedOptions.isNotEmpty && isCoach) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: parsedOptions.map((opt) {
                              return GestureDetector(
                                onTap: () {
                                  if (widget.onOptionSelected != null) {
                                    widget.onOptionSelected!(opt);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    opt,
                                    style: AppTheme.bodyMd.copyWith(color: AppTheme.primary),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        
                        if (widget.message.providerServed != null && isCoach) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Served by ${widget.message.providerServed}',
                            style: AppTheme.labelMd.copyWith(
                              color: AppTheme.textSecondary.withValues(alpha: 0.5),
                              fontSize: 9,
                            ),
                          ),
                        ],
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

class _TypingIndicatorBubble extends StatefulWidget {
  const _TypingIndicatorBubble({super.key});

  @override
  State<_TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<_TypingIndicatorBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMd, right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusMd),
            topRight: Radius.circular(AppTheme.radiusMd),
            bottomLeft: Radius.circular(2),
            bottomRight: Radius.circular(AppTheme.radiusMd),
          ),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final val = math.sin((_controller.value * 2 * math.pi) - (index * math.pi / 4));
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6 + (val > 0 ? val * 4 : 0),
                  decoration: const BoxDecoration(
                    color: AppTheme.textSecondary,
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

Map<String, dynamic> _getToolMetadata(String toolName, bool isWorking, BuildContext context) {
  String title = '';
  IconData icon = Icons.build_circle_outlined;
  
  switch (toolName) {
    case 'query_exercise_database':
      title = isWorking 
        ? context.tr('tool_running_query_exercise_database') 
        : context.tr('tool_done_query_exercise_database');
      icon = Icons.fitness_center_rounded;
      break;
    case 'save_workout_plan':
      title = isWorking 
        ? context.tr('tool_running_save_workout_plan') 
        : context.tr('tool_done_save_workout_plan');
      icon = Icons.bookmark_added_rounded;
      break;
    case 'calculate_macros':
      title = isWorking 
        ? context.tr('tool_running_calculate_macros') 
        : context.tr('tool_done_calculate_macros');
      icon = Icons.restaurant_menu_rounded;
      break;
    default:
      String formatted = toolName.replaceAll('_', ' ');
      formatted = formatted.split(' ').map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1)}' : '').join(' ');
      title = isWorking 
        ? context.tr('tool_custom_running').replaceAll('{}', formatted)
        : context.tr('tool_custom_done').replaceAll('{}', formatted);
      icon = Icons.miscellaneous_services_rounded;
  }
  
  return {'title': title, 'icon': icon};
}

class _ToolGroupBubble extends StatefulWidget {
  final List<ChatMessage> tools;

  const _ToolGroupBubble({required this.tools});

  @override
  State<_ToolGroupBubble> createState() => _ToolGroupBubbleState();
}

class _ToolGroupBubbleState extends State<_ToolGroupBubble> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.tools.isEmpty) return const SizedBox.shrink();
    
    final isFa = Localizations.localeOf(context).languageCode == 'fa';
    bool isWorking = widget.tools.any((t) => t.content.isEmpty);
    
    String headerTitle = '';
    IconData headerIcon = Icons.build_circle_outlined;
    
    // Reverse the tools so they show in chronological order inside the accordion
    final chronoTools = widget.tools.reversed.toList();
    
    if (widget.tools.length == 1) {
      final meta = _getToolMetadata(widget.tools.first.toolName ?? 'unknown', isWorking, context);
      headerTitle = meta['title'];
      headerIcon = meta['icon'];
    } else {
      headerTitle = context.tr('tool_group_summary').replaceAll('{}', widget.tools.length.toString());
      headerIcon = Icons.account_tree_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: AppTheme.gutter),
      child: Align(
        alignment: isFa ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: _isExpanded 
                    ? const BorderRadius.vertical(top: Radius.circular(10)) 
                    : BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      if (isWorking)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                        )
                      else
                        Icon(headerIcon, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          headerTitle,
                          style: AppTheme.labelMd.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExpanded)
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppTheme.outline)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: chronoTools.map((tool) {
                      return _ToolAccordionItem(tool: tool);
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolAccordionItem extends StatelessWidget {
  final ChatMessage tool;

  const _ToolAccordionItem({required this.tool});

  @override
  Widget build(BuildContext context) {
    bool isWorking = tool.content.isEmpty;
    final meta = _getToolMetadata(tool.toolName ?? 'unknown', isWorking, context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isWorking)
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primary),
                )
              else
                Icon(meta['icon'], size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  meta['title'],
                  style: AppTheme.labelMd.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SingleChildScrollView(
              child: Text(
                isWorking ? 'Executing...' : tool.content,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppTheme.textSecondary.withOpacity(0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
