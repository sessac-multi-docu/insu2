import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_session.dart';

class StorageService {
  static const String _sessionListKey = 'chat_sessions';
  
  // 모든 세션 로드
  Future<List<ChatSession>> loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getStringList(_sessionListKey) ?? [];
      
      return sessionsJson
          .map((json) => ChatSession.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('세션 로드 중 오류: $e');
      return [];
    }
  }
  
  // 세션 저장
  Future<bool> saveSession(ChatSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await loadSessions();
      
      // 기존 세션 업데이트 또는 새 세션 추가
      final index = sessions.indexWhere((s) => s.id == session.id);
      if (index >= 0) {
        sessions[index] = session;
      } else {
        sessions.add(session);
      }
      
      // 세션 저장
      final sessionsJson = sessions
          .map((session) => jsonEncode(session.toJson()))
          .toList();
      
      return await prefs.setStringList(_sessionListKey, sessionsJson);
    } catch (e) {
      debugPrint('세션 저장 중 오류: $e');
      return false;
    }
  }
  
  // 세션 삭제
  Future<bool> deleteSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await loadSessions();
      
      sessions.removeWhere((session) => session.id == sessionId);
      
      final sessionsJson = sessions
          .map((session) => jsonEncode(session.toJson()))
          .toList();
      
      return await prefs.setStringList(_sessionListKey, sessionsJson);
    } catch (e) {
      debugPrint('세션 삭제 중 오류: $e');
      return false;
    }
  }
  
  // 모든 세션 삭제
  Future<bool> clearAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_sessionListKey);
    } catch (e) {
      debugPrint('모든 세션 삭제 중 오류: $e');
      return false;
    }
  }
} 