import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

class ChatRepository {
  static const _keySessions = 'chat_sessions';
  final SharedPreferences _prefs;

  ChatRepository(this._prefs);

  List<ChatSession> _loadSessions() {
    final raw = _prefs.getString(_keySessions);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((item) => ChatSession.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveSessions(List<ChatSession> sessions) async {
    final raw = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await _prefs.setString(_keySessions, raw);
  }

  Future<ChatSession> createSession() async {
    final now = DateTime.now();
    final newSession = ChatSession(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'گفتگوی جدید',
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
    final sessions = _loadSessions();
    sessions.add(newSession);
    await _saveSessions(sessions);
    return newSession;
  }

  List<ChatSession> getAllSessions() {
    final sessions = _loadSessions();
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  Future<void> renameSession(String id, String newTitle) async {
    final sessions = _loadSessions();
    final index = sessions.indexWhere((s) => s.id == id);
    if (index != -1) {
      sessions[index] = sessions[index].copyWith(
        title: newTitle,
        updatedAt: DateTime.now(),
      );
      await _saveSessions(sessions);
    }
  }

  Future<void> deleteSession(String id) async {
    final sessions = _loadSessions();
    sessions.removeWhere((s) => s.id == id);
    await _saveSessions(sessions);
  }

  Future<void> addMessage(String sessionId, ChatMessage message) async {
    final sessions = _loadSessions();
    final index = sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final updatedMessages = List<ChatMessage>.from(sessions[index].messages)..add(message);
      // Auto-naming logic (Task 6)
      String title = sessions[index].title;
      if (title == 'گفتگوی جدید' && updatedMessages.isNotEmpty) {
        final firstMsg = updatedMessages.first.content;
        title = firstMsg.length > 30 ? '${firstMsg.substring(0, 30)}...' : firstMsg;
      }
      sessions[index] = sessions[index].copyWith(
        title: title,
        messages: updatedMessages,
        updatedAt: DateTime.now(),
      );
      await _saveSessions(sessions);
    }
  }

  Future<void> editMessage(String sessionId, String messageId, String newContent) async {
    final sessions = _loadSessions();
    final sessionIndex = sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      final messages = sessions[sessionIndex].messages;
      final msgIndex = messages.indexWhere((m) => m.id == messageId);
      if (msgIndex != -1) {
        final updatedMessages = List<ChatMessage>.from(messages);
        updatedMessages[msgIndex] = updatedMessages[msgIndex].copyWith(
          content: newContent,
          isEdited: true,
        );
        sessions[sessionIndex] = sessions[sessionIndex].copyWith(
          messages: updatedMessages,
          updatedAt: DateTime.now(),
        );
        await _saveSessions(sessions);
      }
    }
  }

  Future<void> deleteMessage(String sessionId, String messageId) async {
    final sessions = _loadSessions();
    final sessionIndex = sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      final messages = sessions[sessionIndex].messages;
      final updatedMessages = List<ChatMessage>.from(messages)..removeWhere((m) => m.id == messageId);
      sessions[sessionIndex] = sessions[sessionIndex].copyWith(
        messages: updatedMessages,
        updatedAt: DateTime.now(),
      );
      await _saveSessions(sessions);
    }
  }
}
