import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../models/chat_session.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'package:uuid/uuid.dart';

class ChatProvider with ChangeNotifier {
  final List<Message> _messages = [];
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  bool _isLoading = false;
  bool _processingMessage = false;
  
  // 세션 관련 변수
  List<ChatSession> _sessions = [];
  String? _currentSessionId;

  List<Message> get messages => List.unmodifiable(_messages);
  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;
  bool get processingMessage => _processingMessage;
  
  // 현재 세션 반환
  ChatSession? get currentSession {
    if (_currentSessionId == null) return null;
    
    try {
      return _sessions.firstWhere((s) => s.id == _currentSessionId);
    } catch (e) {
      // 세션을 찾을 수 없는 경우 임시 세션 반환 (저장하지 않음)
      return ChatSession(title: '새 대화');
    }
  }

  // 초기화
  Future<void> initialize() async {
    await _loadSessions();
    if (_sessions.isEmpty) {
      await newSession();
    } else {
      await loadSession(_sessions.first.id);
    }
  }

  // 모든 세션 로드
  Future<void> _loadSessions() async {
    _sessions = await _storageService.loadSessions();
    // 최신 세션이 먼저 오도록 정렬
    _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
  }

  // 새 세션 생성
  Future<ChatSession> newSession() async {
    _messages.clear();
    final newSession = ChatSession();
    _currentSessionId = newSession.id;
    _sessions.insert(0, newSession);
    await _storageService.saveSession(newSession);
    notifyListeners();
    return newSession;
  }

  // 세션 로드
  Future<void> loadSession(String sessionId) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex >= 0) {
      _currentSessionId = sessionId;
      _messages.clear();
      _messages.addAll(_sessions[sessionIndex].messages);
      notifyListeners();
    }
  }

  // 세션 삭제
  Future<void> deleteSession(String sessionId) async {
    await _storageService.deleteSession(sessionId);
    _sessions.removeWhere((s) => s.id == sessionId);
    
    if (_currentSessionId == sessionId) {
      if (_sessions.isNotEmpty) {
        await loadSession(_sessions.first.id);
      } else {
        await newSession();
      }
    }
    
    notifyListeners();
  }

  void addMessage(String text, bool isUser) {
    final message = Message(text: text, isUser: isUser);
    _messages.add(message);
    _saveCurrentSession();
    notifyListeners();
  }

  Future<bool> sendMessage(String text, {bool shouldProcess = true}) async {
    if (text.trim().isEmpty) return false;

    try {
      // 사용자 메시지 추가
      final userMessage = Message(
        id: const Uuid().v4(),
        sender: "사용자",
        text: text,
        timestamp: DateTime.now(),
        isUser: true,
      );
      _messages.add(userMessage);
      notifyListeners();

      if (shouldProcess) {
        _processingMessage = true;
        notifyListeners();

        try {
          // 새 API 호출 메서드 사용 (대화 이력 전달)
          final apiResponse = await _apiService.searchQuery(text, _messages);
          
          // 응답에서 필요한 정보 추출
          final String answer = apiResponse['answer'] ?? '응답을 처리하는 중 오류가 발생했습니다.';
          final List<dynamic> collectionsUsed = apiResponse['collections_used'] ?? [];
          
          // 봇 메시지 추가
          final botMessage = Message(
            id: const Uuid().v4(),
            sender: "인슈판다",
            text: answer,
            timestamp: DateTime.now(),
            isUser: false,
            metadata: {
              'collections_used': collectionsUsed,
            }
          );
          _messages.add(botMessage);
          
          // 현재 세션 저장
          _saveCurrentSession();
        } catch (e) {
          // 에러 처리
          final errorMessage = Message(
            id: const Uuid().v4(),
            sender: "인슈판다",
            text: "죄송합니다, 응답을 처리하는 중 오류가 발생했습니다: $e",
            timestamp: DateTime.now(),
            isUser: false,
          );
          _messages.add(errorMessage);
        } finally {
          _processingMessage = false;
          notifyListeners();
        }
      }

      return true;
    } catch (e) {
      print('메시지 전송 중 오류: $e');
      return false;
    }
  }

  Future<void> sendVoiceMessage(File audioFile) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 음성 파일 전송
      final response = await _apiService.transcribeAudio(audioFile);
      
      // 인식된 텍스트를 사용자 메시지로 추가
      addMessage(response['transcription'], true);
      
      // 봇 응답 추가
      addMessage(response['answer'], false);
    } catch (e) {
      addMessage('음성 인식 중 오류가 발생했습니다: $e', false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 현재 세션 저장
  Future<void> _saveCurrentSession() async {
    if (_currentSessionId == null) return;
    
    final sessionIndex = _sessions.indexWhere((s) => s.id == _currentSessionId);
    if (sessionIndex >= 0) {
      // 세션 업데이트
      ChatSession updatedSession = _sessions[sessionIndex].copyWith(
        messages: List<Message>.from(_messages),
      );
      
      // 첫 메시지가 있을 경우 제목 업데이트
      if (_messages.isNotEmpty && updatedSession.title == '새 대화') {
        updatedSession = updatedSession.copyWith(
          title: updatedSession.generateTitle(),
        );
      }
      
      _sessions[sessionIndex] = updatedSession;
      await _storageService.saveSession(updatedSession);
      notifyListeners();
    }
  }

  // 새 채팅 세션 시작
  Future<void> startNewChat() async {
    try {
      // 세션 ID 초기화
      await _apiService.resetSessionId();
      
      // 새 세션 생성
      final timestamp = DateTime.now();
      final sessionId = const Uuid().v4();
      final newSession = ChatSession(
        id: sessionId,
        name: _formatSessionName(timestamp),
        createdAt: timestamp,
        updatedAt: timestamp,
      );

      _currentSessionId = sessionId;
      _messages.clear();
      _sessions[sessionId] = newSession;
      
      // 저장
      await _saveSession(newSession);
      await _saveSessionList();
      
      notifyListeners();
    } catch (e) {
      print('새 채팅 시작 중 오류: $e');
    }
  }

  // 현재 세션 설정
  Future<void> setCurrentSession(String sessionId) async {
    await loadSession(sessionId);
  }

  // 세션 제목 업데이트
  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex >= 0) {
      final updatedSession = _sessions[sessionIndex].copyWith(
        title: newTitle,
      );
      _sessions[sessionIndex] = updatedSession;
      await _storageService.saveSession(updatedSession);
      notifyListeners();
    }
  }
} 