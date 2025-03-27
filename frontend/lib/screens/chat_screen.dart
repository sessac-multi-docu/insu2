import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/voice_recorder.dart';
import '../widgets/chat_sidebar.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showSidebar = true;
  bool _isModalVisible = false;

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 채팅 프로바이더 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();
    _focusNode.requestFocus();

    final chatProvider = context.read<ChatProvider>();
    chatProvider.sendMessage(text).then((_) => _scrollToBottom());
  }

  void _showNewSessionModal() {
    setState(() {
      _isModalVisible = true;
    });

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('새 대화 시작'),
        message: const Text('새 대화를 시작하시겠습니까?\n현재 대화는 사이드바에서 다시 볼 수 있습니다.'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              context.read<ChatProvider>().newSession();
              Navigator.pop(context);
              setState(() {
                _isModalVisible = false;
              });
            },
            child: const Text('새 대화 시작'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            setState(() {
              _isModalVisible = false;
            });
          },
          child: const Text('취소'),
        ),
      ),
    );
  }

  void _showClearMessagesModal() {
    setState(() {
      _isModalVisible = true;
    });

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('대화 지우기'),
        message: const Text('현재 대화의 모든 메시지를 지우시겠습니까?\n이 작업은 취소할 수 없습니다.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              context.read<ChatProvider>().clearMessages();
              Navigator.pop(context);
              setState(() {
                _isModalVisible = false;
              });
            },
            child: const Text('대화 지우기'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            setState(() {
              _isModalVisible = false;
            });
          },
          child: const Text('취소'),
        ),
      ),
    );
  }

  void _showMobileSidebarModal() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark
              ? AppTheme.darkSidebarBackground
              : AppTheme.lightSidebarBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            // 드래그 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '대화 기록',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // 채팅 사이드바 내용
            const Expanded(child: ChatSidebar()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark;
    final chatProvider = context.watch<ChatProvider>();
    final isWideScreen = MediaQuery.of(context).size.width > 768;

    return CupertinoPageScaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackground : AppTheme.lightBackground,
      child: Row(
        children: [
          // 사이드바 (반응형) - 넓은 화면에서만 표시
          if (_showSidebar && isWideScreen) const ChatSidebar(),

          // 메인 채팅 영역
          Expanded(
            child: Column(
              children: [
                // 앱바
                _buildAppBar(isDarkMode),

                // 채팅 메시지 영역
                Expanded(
                  child: Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      final messages = chatProvider.messages;

                      // 메시지가 없을 때 웰컴 화면 표시
                      if (messages.isEmpty) {
                        return _buildWelcomeScreen(isDarkMode);
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return MessageBubble(
                            message: messages[index],
                            isDarkMode: isDarkMode,
                          );
                        },
                      );
                    },
                  ),
                ),

                // 로딩 표시기
                if (chatProvider.isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SpinKitThreeBounce(
                      color: isDarkMode ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                      size: 20.0,
                    ),
                  ),

                // 입력 영역
                _buildInputArea(isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen(bool isDarkMode) {
    final textColor = isDarkMode
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    final primaryColor = isDarkMode
        ? AppTheme.darkPrimary
        : AppTheme.lightPrimary;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  'assets/chatgpt_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '보험 GA 도우미 인슈판다에 오신 것을 환영합니다',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '질문을 입력하거나 음성으로 물어보세요',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildExamplePrompt('DB손해보험의 실손의료보험에서 비급여 항목 보장 범위가 어떻게 되나요?', isDarkMode),
              _buildExamplePrompt('삼성화재와 KB손해보험 중에 실비보험 보험료가 더 저렴한 곳은?', isDarkMode),
              _buildExamplePrompt('DB손해보험과 하나손해보험의 실비보험 약관에서 통원치료비 보장 한도와 보험료 차이점은?', isDarkMode),
              _buildExamplePrompt('암보험 중 고액암 보장금이 가장 높은 상품과 일반암 보장금이 높은 상품의 약관 차이 및 보험료 비교', isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamplePrompt(String text, bool isDarkMode) {
    final backgroundcolor = isDarkMode
        ? Colors.grey[800]
        : Colors.grey[200];
    final textColor = isDarkMode
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          _textController.text = text;
          _handleSubmitted(text);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundcolor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.chat_bubble,
                size: 16,
                color: textColor.withOpacity(0.6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDarkMode) {
    final textColor = isDarkMode
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    final primaryColor = isDarkMode
        ? AppTheme.darkPrimary
        : AppTheme.lightPrimary;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkBackground : AppTheme.lightBackground,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // 사이드바 토글 버튼 추가
            MediaQuery.of(context).size.width > 768
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _showSidebar = !_showSidebar;
                      });
                    },
                    child: Icon(
                      _showSidebar ? CupertinoIcons.sidebar_left : CupertinoIcons.text_alignleft,
                      color: primaryColor,
                      size: 24,
                    ),
                  )
                : CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      // 모바일 환경에서는 사이드바를 모달로 표시
                      _showMobileSidebarModal();
                    },
                    child: Icon(
                      CupertinoIcons.chat_bubble_2,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),

            const SizedBox(width: 8),

            // 현재 세션 제목 표시
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, child) {
                  final session = provider.currentSession;
                  return Text(
                    session?.title ?? '새 대화',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),

            // 우측 액션 버튼들
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showNewSessionModal,
              child: Icon(
                CupertinoIcons.plus_square,
                color: primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showClearMessagesModal,
              child: Icon(
                CupertinoIcons.delete,
                color: primaryColor,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDarkMode) {
    final backgroundColor = isDarkMode
        ? AppTheme.darkSurface
        : AppTheme.lightSurface;
    final textColor = isDarkMode
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    final borderColor = isDarkMode
        ? Colors.grey[800]!
        : Colors.grey[300]!;
    final inputBackgroundColor = isDarkMode
        ? Color(0xFF40414f)
        : Colors.grey[200]!;
    final primaryColor = isDarkMode
        ? AppTheme.darkPrimary
        : AppTheme.lightPrimary;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: inputBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: borderColor,
                      width: 0.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoTextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          placeholder: '질문을 입력하세요...',
                          placeholderStyle: TextStyle(
                            color: textColor.withOpacity(0.5),
                            fontSize: 14,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 12.0,
                          ),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSubmitted: chatProvider.isLoading ? null : _handleSubmitted,
                          enabled: !chatProvider.isLoading,
                          cursorColor: primaryColor,
                          minLines: 1,
                          maxLines: 5,
                        ),
                      ),
                      const VoiceRecorder(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: chatProvider.isLoading
                    ? null
                    : () => _handleSubmitted(_textController.text),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    chatProvider.isLoading
                        ? CupertinoIcons.hourglass
                        : CupertinoIcons.arrow_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}