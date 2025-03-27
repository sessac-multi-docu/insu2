import 'dart:io';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';

// 웹용 recorder와 모바일용 recorder를 구분하는 인터페이스
abstract class PlatformVoiceRecorder {
  Future<void> init();
  Future<void> startRecording();
  Future<void> stopRecording(BuildContext context);
  void dispose();
}

// 모바일용 recorder 구현
class MobileVoiceRecorder implements PlatformVoiceRecorder {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  String? _recordingPath;
  
  @override
  Future<void> init() async {
    await _recorder.openRecorder();
    await _requestPermissions();
  }
  
  Future<void> _requestPermissions() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('마이크 권한이 필요합니다.');
    }
  }
  
  @override
  Future<void> startRecording() async {
    try {
      final directory = await getTemporaryDirectory();
      _recordingPath = '${directory.path}/audio_message.wav';
      
      await _recorder.startRecorder(
        toFile: _recordingPath,
        codec: Codec.pcm16WAV,
      );
    } catch (e) {
      debugPrint('Error recording audio on mobile: $e');
    }
  }
  
  @override
  Future<void> stopRecording(BuildContext context) async {
    try {
      final path = await _recorder.stopRecorder();
      if (path != null) {
        final chatProvider = context.read<ChatProvider>();
        await chatProvider.sendVoiceMessage(File(path));
      }
    } catch (e) {
      debugPrint('Error stopping mobile recording: $e');
    }
  }
  
  @override
  void dispose() {
    _recorder.closeRecorder();
  }
}

// 웹용 recorder 구현
class WebVoiceRecorder implements PlatformVoiceRecorder {
  html.MediaRecorder? _mediaRecorder;
  List<html.Blob> _audioChunks = [];
  
  @override
  Future<void> init() async {
    // 웹에서는 녹음기가 시작될 때 권한 요청
  }
  
  @override
  Future<void> startRecording() async {
    try {
      // 사용자에게 마이크 권한 요청
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'audio': true
      });
      
      if (stream != null) {
        _audioChunks = [];
        _mediaRecorder = html.MediaRecorder(stream);
        
        _mediaRecorder?.addEventListener('dataavailable', (html.Event event) {
          final blobEvent = event as html.BlobEvent;
          if (blobEvent.data != null) {
            _audioChunks.add(blobEvent.data!);
          }
        });
        
        _mediaRecorder?.start();
      }
    } catch (e) {
      debugPrint('Error recording audio on web: $e');
    }
  }
  
  @override
  Future<void> stopRecording(BuildContext context) async {
    try {
      if (_mediaRecorder != null) {
        // mediaRecorder 상태 확인
        if (_mediaRecorder?.state == 'recording') {
          final completer = Completer<void>();
          
          _mediaRecorder?.addEventListener('stop', (html.Event event) {
            _sendWebAudioToServer(context).then((_) {
              completer.complete();
            }).catchError((e) {
              completer.completeError(e);
            });
          });
          
          _mediaRecorder?.stop();
          await completer.future;
        }
      }
    } catch (e) {
      debugPrint('Error stopping web recording: $e');
    }
  }
  
  Future<void> _sendWebAudioToServer(BuildContext context) async {
    if (_audioChunks.isEmpty) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.addMessage('음성이 녹음되지 않았습니다. 다시 시도해주세요.', false);
      return;
    }
    
    try {
      // Blob을 합치고 FormData 생성
      final blob = html.Blob(_audioChunks, 'audio/wav');
      final url = html.Url.createObjectUrl(blob);
      
      // Fetch API를 사용하여 서버에 오디오 전송
      final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080';
      final response = await html.window.fetch('$apiUrl/transcribe', {
        'method': 'POST',
        'body': blob,
      });
      
      if (response.status == 200) {
        final jsonResponse = await response.json();
        final chatProvider = context.read<ChatProvider>();
        chatProvider.addDirectMessage(jsonResponse);
      } else {
        throw Exception('Server responded with status: ${response.status}');
      }
    } catch (e) {
      debugPrint('Error sending web audio to server: $e');
      final chatProvider = context.read<ChatProvider>();
      chatProvider.addMessage('음성 처리 중 오류가 발생했습니다: $e', false);
    }
  }
  
  @override
  void dispose() {
    if (_mediaRecorder != null) {
      if (_mediaRecorder?.state == 'recording') {
        _mediaRecorder?.stop();
      }
      _mediaRecorder = null;
    }
  }
}

// 메인 위젯
class VoiceRecorder extends StatefulWidget {
  const VoiceRecorder({Key? key}) : super(key: key);

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  late final PlatformVoiceRecorder _platformRecorder;
  bool _isRecording = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _platformRecorder = kIsWeb
        ? WebVoiceRecorder()
        : MobileVoiceRecorder();
    
    _platformRecorder.init();
  }

  @override
  void dispose() {
    _platformRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() {
      _isInitializing = true;
    });
    
    try {
      await _platformRecorder.startRecording();
      setState(() {
        _isRecording = true;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
      });
      _showError('마이크 접근 권한이 필요합니다.');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    setState(() {
      _isInitializing = true;
    });
    
    try {
      await _platformRecorder.stopRecording(context);
    } catch (e) {
      _showError('음성 처리 중 오류가 발생했습니다.');
    } finally {
      setState(() {
        _isRecording = false;
        _isInitializing = false;
      });
    }
  }

  void _showError(String message) {
    if (!context.mounted) return;
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('확인'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark;
    final primaryColor = isDarkMode 
        ? AppTheme.darkPrimary 
        : AppTheme.lightPrimary;
    
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _isInitializing 
          ? null 
          : (_isRecording ? _stopRecording : _startRecording),
      child: _isInitializing
          ? SizedBox(
              width: 24,
              height: 24,
              child: CupertinoActivityIndicator(
                radius: 10,
                color: primaryColor,
              ),
            )
          : Icon(
              _isRecording 
                  ? CupertinoIcons.stop_fill
                  : CupertinoIcons.mic_fill,
              color: _isRecording 
                  ? CupertinoColors.systemRed
                  : isDarkMode
                      ? AppTheme.darkTextPrimary.withOpacity(0.7)
                      : AppTheme.lightTextPrimary.withOpacity(0.7),
              size: 22,
            ),
    );
  }
} 