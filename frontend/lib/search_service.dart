import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:universal_io/io.dart';

// 웹 환경에서만 사용할 라이브러리
import 'dart:js_util' if (dart.library.html) 'dart:js_util';

// 검색 결과를 담는 클래스
class SearchResult {
  final bool isSuccess;
  final Map<String, dynamic> data;
  final int statusCode;
  final String error;

  SearchResult({
    required this.isSuccess,
    this.data = const {},
    this.statusCode = 0,
    this.error = '',
  });
}

// 검색 서비스 - 웹과 네이티브 플랫폼을 모두 지원
class SearchService {
  // 사용 가능한 CORS 프록시 목록
  static final List<String> _corsProxies = [
    'https://corsproxy.io/?',
    'https://cors-anywhere.herokuapp.com/',
    'https://api.allorigins.win/raw?url=',
    'https://proxy.cors.sh/',
    'https://thingproxy.freeboard.io/fetch/',
    'https://api.codetabs.com/v1/proxy?quest=',
  ];

  // 다양한 서버 URL을 시도하기 위한 리스트
  static List<String> _getServerUrls(String query) {
    final apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api/search';
     return [apiUrl];
  }
  // 검색 기능 구현
  static Future<SearchResult> search(String apiUrl, String query) async {
    final serverUrls = _getServerUrls(query);

    // 모든 가능한 URL 순차적으로 시도
    if (kIsWeb) {
      // 웹 환경에서는 특수 처리
      return _webSearch(serverUrls, query);
    } else {
      // 모바일 환경에서는 http 패키지 사용
      return _mobileSearch(apiUrl, query);
    }
  }

  // 웹 환경에서의 검색 구현
  static Future<SearchResult> _webSearch(
    List<String> serverUrls,
    String query,
  ) async {
    debugPrint('웹 환경에서 검색 시도: 서버 URL 개수 ${serverUrls.length}');
    Exception? lastError;

    try {
      debugPrint('테스트 API 요청 시도: /test-api');
      // 요청 형식 수정
      final requestBody = {
        "query": query,
        "collections": [],
      };
      debugPrint('요청 본문: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
            Uri.parse('/test-api'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return SearchResult(
            isSuccess: true,
            data: data,
            statusCode: response.statusCode,
          );
        } catch (e) {
          debugPrint('JSON 파싱 오류: $e');
        }
      } else {
        debugPrint('HTTP 오류: ${response.statusCode}, 응답: ${response.body}');
      }
    } catch (e) {
      debugPrint('테스트 API 요청 실패: $e');
      lastError = e as Exception;
    }

    // 1단계: 모든 서버 URL 직접 시도
    for (final apiUrl in serverUrls) {
      try {
        debugPrint('일반 HTTP 요청 시도: $apiUrl');
        // 요청 형식 수정
        final requestBody = {
          "query": {"query": query},
          "collections": [],
        };
        debugPrint('검색 요청 전송 - 쿼리: "$query"');
        debugPrint('요청 본문: ${jsonEncode(requestBody)}');

        final response = await http
            .post(
              Uri.parse(apiUrl),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Connection': 'keep-alive',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body);
            return SearchResult(
              isSuccess: true,
              data: data,
              statusCode: response.statusCode,
            );
          } catch (e) {
            debugPrint('JSON 파싱 오류: $e');
          }
        } else {
          debugPrint('HTTP 오류: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('API 직접 요청 실패: $apiUrl - $e');
        lastError = e as Exception;
      }
    }

    // 2단계: JSON-P 방식 시도
    for (final apiUrl in serverUrls) {
      if (apiUrl.contains("localhost") || apiUrl.contains("127.0.0.1")) {
        try {
          // GET 방식 요청
          final getUrl = apiUrl + "?query=" + Uri.encodeComponent(query);
          debugPrint('GET 방식 요청 시도: $getUrl');
          final getResponse = await http
              .get(
                Uri.parse(getUrl),
                headers: {
                  'Accept': 'application/json',
                  'Access-Control-Allow-Origin': '*',
                },
              )
              .timeout(const Duration(seconds: 5));

          if (getResponse.statusCode == 200) {
            try {
              final data = jsonDecode(getResponse.body);
              return SearchResult(
                isSuccess: true,
                data: data,
                statusCode: getResponse.statusCode,
              );
            } catch (e) {
              debugPrint('JSON 파싱 오류 (GET): $e');
            }
          }
        } catch (e) {
          debugPrint('GET 방식 요청 실패: $apiUrl - $e');
        }
      }
    }

    // 3단계: CORS 프록시 시도
    for (final proxy in _corsProxies) {
      for (final apiUrl in serverUrls) {
        // 로컬호스트는 프록시가 접근할 수 없으므로 IP만 시도
        if (apiUrl.contains("172.16.216.85")) {
          try {
            debugPrint('CORS 프록시 시도: $proxy$apiUrl');
            final proxyUrl = proxy + apiUrl;
            final proxyResponse = await http
                .post(
                  Uri.parse(proxyUrl),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'query': query}),
                )
                .timeout(const Duration(seconds: 5));

            if (proxyResponse.statusCode == 200) {
              try {
                final data = jsonDecode(proxyResponse.body);
                return SearchResult(
                  isSuccess: true,
                  data: data,
                  statusCode: proxyResponse.statusCode,
                );
              } catch (jsonError) {
                debugPrint('프록시 응답 JSON 파싱 오류: $jsonError');
              }
            }
          } catch (proxyError) {
            debugPrint('프록시 $proxy 사용 실패: $proxyError');
          }
        }
      }
    }

    // 모든 시도가 실패한 경우
    return SearchResult(
      isSuccess: false,
      error:
          "모든 통신 시도가 실패했습니다. CORS 정책 문제 또는 서버가 응답하지 않습니다.\n마지막 오류: ${lastError?.toString() ?? '알 수 없음'}",
    );
  }

  // 모바일 환경에서의 검색 구현
  static Future<SearchResult> _mobileSearch(String apiUrl, String query) async {
    try {
      debugPrint('모바일 환경 API 요청: $apiUrl');
      final requestBody = {
        "query": {"query": query},
        "collections": [],
      };
      debugPrint('요청 본문: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SearchResult(
          isSuccess: true,
          data: data,
          statusCode: response.statusCode,
        );
      } else {
        debugPrint('HTTP 오류: ${response.statusCode}, 응답: ${response.body}');
        return SearchResult(
          isSuccess: false,
          statusCode: response.statusCode,
          error: response.body,
        );
      }
    } catch (e) {
      debugPrint('모바일 검색 중 오류: $e');
      return SearchResult(isSuccess: false, error: e.toString());
    }
  }
}
