import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/chat_models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // API URL
  final String _baseUrl = '/api/search'; // 상대 경로 사용

  // 웹 환경인지 확인
  bool get isWeb => kIsWeb;

  // 적절한 URL 생성 (웹과 모바일 환경에 따라)
  String getApiUrl(String path) {
    if (isWeb) {
      // 웹에서 실행 중이면 상대 경로 사용
      return path;
    } else {
      // 모바일에서는 전체 URL 필요
      return 'http://172.16.216.85:8000$path';
    }
  }

  // UTF-8 디코딩을 명시적으로 처리하는 함수
  String decodeUtf8Response(http.Response response) {
    // 응답 헤더 확인
    final contentType = response.headers['content-type'] ?? '';
    debugPrint('응답 콘텐츠 타입: $contentType');

    // UTF-8로 명시적 디코딩
    try {
      return utf8.decode(response.bodyBytes);
    } catch (e) {
      debugPrint('UTF-8 디코딩 오류: $e');
      return response.body; // 원본 반환
    }
  }

  // 세션 ID 가져오기 또는 생성
  Future<String> getSessionId() async {
    final storage = FlutterSecureStorage();
    String? sessionId = await storage.read(key: 'chat_session_id');
    if (sessionId == null) {
      final uuid = Uuid();
      sessionId = uuid.v4(); // 새 UUID 생성
      await storage.write(key: 'chat_session_id', value: sessionId);
    }
    return sessionId;
  }

  // 표준 API 응답 형식
  Map<String, dynamic> _standardErrorResponse(String message) {
    return {
      'answer': '오류가 발생했습니다: $message',
      'collections_used': [],
      'error': message,
      'session_id': '',
      'chat_history': []
    };
  }

  // API 호출 함수 (채팅 이력 포함)
  Future<Map<String, dynamic>> searchQuery(String query, List<Message> chatHistory) async {
    try {
      final sessionId = await getSessionId();
      
      // 채팅 이력을 API 형식으로 변환
      final formattedHistory = chatHistory.map((msg) => {
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text
      }).toList();
      
      // API 요청 본문 구성
      final requestBody = {
        'query_text': query,
        'collections': <String>[],
        'session_id': sessionId,
        'chat_history': formattedHistory
      };
      
      // HTTP POST 요청
      final url = getApiUrl('/api/search');
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data;
      } else {
        return _standardErrorResponse('API 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      return _standardErrorResponse('API 요청 실패: $e');
    }
  }

  // 세션 ID 초기화 (새로운 대화 시작 시)
  Future<void> resetSessionId() async {
    final storage = FlutterSecureStorage();
    final newSessionId = Uuid().v4();
    await storage.write(key: 'chat_session_id', value: newSessionId);
  }

  // 검색 쿼리 요청
  Future<String> searchQueryOld(String query) async {
    try {
      debugPrint('검색 쿼리 요청: $query');

      // API URL - 프록시 서버를 통해 요청 (상대 경로 사용)
      final url = '/api/search';
      debugPrint('사용 URL: $url');

      // 쿼리만 포함한 요청 본문 구성 (서버가 자동으로 컬렉션을 선택하도록)
      final requestBody = {
        "query": {"query": query},
      };

      debugPrint('요청 본문: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('응답 상태 코드: ${response.statusCode}');

      // UTF-8 디코딩을 명시적으로 처리
      final decodedBody = decodeUtf8Response(response);
      debugPrint('디코딩된 응답 바디: $decodedBody');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(decodedBody);
        return jsonResponse['answer'] ?? '응답을 받지 못했습니다.';
      } else {
        return '서버 오류: ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      debugPrint('API 요청 오류 발생: $e');
      return 'API 요청 오류: $e';
    }
  }

  // 음성 파일 전송 (한글 디코딩 로직 추가)
  Future<Map<String, dynamic>> transcribeAudio(File audioFile) async {
    try {
      // 음성 처리 API URL
      final url = getApiUrl('/api/transcribe');

      // 요청 바디 생성
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // 파일 스트림 추가
      request.files.add(
        await http.MultipartFile.fromPath('audio', audioFile.path),
      );

      // 요청 보내기
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // UTF-8 디코딩을 명시적으로 처리
      final decodedBody = decodeUtf8Response(response);

      if (response.statusCode == 200) {
        return jsonDecode(decodedBody);
      } else {
        return {'error': '음성 처리 실패: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': '음성 요청 오류: $e'};
    }
  }

  // 테스트 API 엔드포인트를 위한 요청 형식 수정 (한글 디코딩 로직 추가)
  Future<String> testQuery(String query) async {
    try {
      final url = getApiUrl('/test-api');

      // curl과 동일한 형식으로 요청 본문 구성
      final requestBody = {
        "query": {"query": query},
      };

      debugPrint('테스트 API 요청: $url');
      debugPrint('요청 본문: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('테스트 응답 상태 코드: ${response.statusCode}');

      // UTF-8 디코딩을 명시적으로 처리
      final decodedBody = decodeUtf8Response(response);
      debugPrint('디코딩된 테스트 응답 바디: $decodedBody');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(decodedBody);
        return jsonResponse['answer'] ?? '응답을 받지 못했습니다.';
      } else {
        return '테스트 API 오류: ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      debugPrint('테스트 API 요청 오류: $e');
      return '테스트 API 요청 오류: $e';
    }
  }
}
