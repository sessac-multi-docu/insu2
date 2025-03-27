import 'package:uuid/uuid.dart';
import 'message.dart';

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Message> messages;

  ChatSession({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Message>? messages,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.title = title ?? '새 대화',
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now(),
    this.messages = messages ?? [];

  // 새 메시지가 추가된 새 세션 반환
  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Message>? messages,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      messages: messages ?? this.messages,
    );
  }

  // 첫 번째 메시지를 기반으로 제목 생성
  String generateTitle() {
    if (messages.isEmpty) return '새 대화';
    
    // 첫 번째 사용자 메시지를 기반으로 제목 생성
    final firstUserMessage = messages.firstWhere(
      (message) => message.isUser, 
      orElse: () => Message(text: '새 대화', isUser: true)
    );
    
    // 제목을 사용자 메시지 텍스트의 처음 30자로 설정
    String title = firstUserMessage.text.trim();
    if (title.length > 30) {
      title = '${title.substring(0, 27)}...';
    }
    
    return title;
  }

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  // JSON 역직렬화
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      messages: (json['messages'] as List)
          .map((m) => Message.fromJson(m))
          .toList(),
    );
  }
} 