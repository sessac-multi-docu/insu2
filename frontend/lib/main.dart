import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'screens/chat_screen.dart';
import 'providers/chat_provider.dart';
import 'theme/app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// 조건부 임포트 - 웹 또는 모바일 환경에 따라 다른 구현 사용
import 'search_service.dart';
// JSON 요청을 위한 모델 클래스
import 'package:flutter/foundation.dart';

class SearchModel {
  final String query;
  
  SearchModel({required this.query});
  
  Map<String, dynamic> toJson() => {'query': query};
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } catch (e) {
    debugPrint('Error loading .env file: $e');
    // 기본값 설정 - 상대 경로 사용
    dotenv.env['API_URL'] = '/api/search';
    // 다른 필요한 변수들은 그대로 두기
  }
  
  // 상태바 스타일 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  
  // 에셋 프리로드
  await _preloadAssets();
  
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  runApp(MyApp(savedThemeMode: savedThemeMode));
}

Future<void> _preloadAssets() async {
  // 앱에서 사용하는 에셋 이미지를 미리 로드
  try {
    // 이미지 프리로드는 앱 초기화 후에 진행하도록 변경
    debugPrint('Asset preloading will happen after app initialization');
  } catch (e) {
    debugPrint('Error preloading assets: $e');
  }
}

class MyApp extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;
  
  const MyApp({Key? key, this.savedThemeMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: AdaptiveTheme(
        light: AppTheme.getLightTheme(),
        dark: AppTheme.getDarkTheme(),
        initial: savedThemeMode ?? AdaptiveThemeMode.system,
        builder: (theme, darkTheme) => MaterialApp(
          title: '인슈판다: 보험세일즈에 강력한 귀요미',
          theme: theme,
          darkTheme: darkTheme,
          home: const ChatScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  final String title;
  
  SearchPage({required this.title});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _responseText = '';
  bool _isLoading = false;
  
  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
      _responseText = '';
    });
    
    // API URL 수정: dotenv에서 가져오거나 기본값 사용
    final apiUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/search';
    debugPrint("요청 URL: $apiUrl");
    
    try {
      debugPrint("요청 시작: $query");
      
      // search_service.dart의 함수를 호출하여 CORS 문제 해결
      final result = await SearchService.search(apiUrl, query);
      
      if (result.isSuccess) {
        setState(() {
          _responseText = result.data['answer'] ?? '응답이 없습니다.';
        });
      } else {
        setState(() {
          _responseText = '서버 오류: ${result.statusCode}\n본문: ${result.error}';
        });
      }
    } catch (e) {
      debugPrint("통신 오류 발생: $e");
      setState(() {
        if (e.toString().contains('XMLHttpRequest error')) {
          _responseText = 'CORS 정책 오류: 서버에서 접근을 허용하지 않습니다.\n\n개발자 정보: ${e.runtimeType}';
        } else if (e.toString().contains('SocketException')) {
          _responseText = '네트워크 연결 오류: 서버에 연결할 수 없습니다.\n\n개발자 정보: ${e.runtimeType}';
        } else if (e.toString().contains('TimeoutException')) {
          _responseText = '요청 시간 초과: 서버 응답이 너무 느립니다.\n\n개발자 정보: ${e.runtimeType}';
        } else {
          _responseText = '알 수 없는 오류: $e\n\n개발자 정보: ${e.runtimeType}';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: '검색어 입력'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                final query = _controller.text;
                if (query.isNotEmpty) {
                  _search(query);
                }
              },
              child: _isLoading 
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('검색'),
            ),
            SizedBox(height: 16.0),
            Expanded(child: SingleChildScrollView(child: Text(_responseText))),
          ],
        ),
      ),
    );
  }
}
