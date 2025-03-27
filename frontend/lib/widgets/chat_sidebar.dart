import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_session.dart';
import '../theme/app_theme.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ChatSidebar extends StatelessWidget {
  const ChatSidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final currentSession = chatProvider.currentSession;
    final isDarkMode = AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark;
    final sidebarColor = isDarkMode 
        ? AppTheme.darkSidebarBackground 
        : AppTheme.lightSidebarBackground;
    final textColor = isDarkMode 
        ? AppTheme.darkTextPrimary 
        : AppTheme.lightTextPrimary;

    return Container(
      width: 280,
      color: sidebarColor,
      child: Column(
        children: [
          _buildHeader(context, chatProvider, isDarkMode),
          _buildModeSwitch(context, isDarkMode),
          Expanded(
            child: _buildSessionList(context, chatProvider, isDarkMode),
          ),
          _buildFooter(context, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ChatProvider chatProvider, bool isDarkMode) {
    final primaryColor = isDarkMode 
        ? AppTheme.darkPrimary 
        : AppTheme.lightPrimary;
    final textColor = isDarkMode 
        ? AppTheme.darkTextPrimary 
        : AppTheme.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSidebarBackground : AppTheme.lightSidebarBackground,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  onPressed: () => chatProvider.newSession(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.plus,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '새 대화',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitch(BuildContext context, bool isDarkMode) {
    final textColor = isDarkMode 
        ? AppTheme.darkTextPrimary 
        : AppTheme.lightTextPrimary;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '다크 모드',
            style: TextStyle(
              color: textColor,
              fontSize: 15,
            ),
          ),
          CupertinoSwitch(
            value: isDarkMode,
            activeColor: AppTheme.darkPrimary,
            onChanged: (value) {
              if (value) {
                AdaptiveTheme.of(context).setDark();
              } else {
                AdaptiveTheme.of(context).setLight();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList(BuildContext context, ChatProvider chatProvider, bool isDarkMode) {
    final sessions = chatProvider.sessions;
    final currentSession = chatProvider.currentSession;
    final textColor = isDarkMode 
        ? AppTheme.darkTextPrimary 
        : AppTheme.lightTextPrimary;

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.chat_bubble_2,
              size: 40,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '대화 내역이 없습니다.',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새 대화를 시작해보세요.',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[500] : Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sessions.length,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemBuilder: (context, index) {
        final session = sessions[index];
        final isSelected = currentSession?.id == session.id;

        return _buildSessionTile(
          context,
          session,
          isSelected,
          chatProvider,
          isDarkMode,
        );
      },
    );
  }

  Widget _buildSessionTile(
    BuildContext context,
    ChatSession session,
    bool isSelected,
    ChatProvider chatProvider,
    bool isDarkMode,
  ) {
    final selectedColor = isDarkMode 
        ? Color(0xFF343541) 
        : Color(0xFFE5E5EA);
    final hoverColor = isDarkMode 
        ? Color(0xFF2A2B32) 
        : Color(0xFFEFEFF4);
    final textColor = isDarkMode 
        ? AppTheme.darkTextPrimary 
        : AppTheme.lightTextPrimary;
    final primaryColor = isDarkMode 
        ? AppTheme.darkPrimary 
        : AppTheme.lightPrimary;

    final lastMessageText = session.messages.isNotEmpty 
        ? session.messages.last.text 
        : '';
    final truncatedMessage = lastMessageText.length > 40 
        ? '${lastMessageText.substring(0, 40)}...' 
        : lastMessageText;

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _shareSession(context, session),
            backgroundColor: CupertinoColors.systemGreen,
            foregroundColor: Colors.white,
            icon: CupertinoIcons.share,
            label: '공유',
            borderRadius: BorderRadius.circular(8),
          ),
          SlidableAction(
            onPressed: (context) => _showDeleteDialog(context, session, chatProvider),
            backgroundColor: CupertinoColors.systemRed,
            foregroundColor: Colors.white,
            icon: CupertinoIcons.delete,
            label: '삭제',
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8.0),
            hoverColor: isSelected ? Colors.transparent : hoverColor,
            onTap: () {
              if (!isSelected && session.id != null) {
                chatProvider.setCurrentSession(session.id!);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.chat_bubble_text,
                    color: isSelected ? primaryColor : textColor.withOpacity(0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (truncatedMessage.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            truncatedMessage,
                            style: TextStyle(
                              color: textColor.withOpacity(0.5),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildSessionMenu(context, session, chatProvider, isDarkMode),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionMenu(
    BuildContext context,
    ChatSession session,
    ChatProvider chatProvider,
    bool isDarkMode,
  ) {
    final textColor = isDarkMode 
        ? AppTheme.darkTextPrimary 
        : AppTheme.lightTextPrimary;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      child: Icon(
        CupertinoIcons.ellipsis_vertical,
        color: textColor.withOpacity(0.6),
        size: 16,
      ),
      onPressed: () {
        showCupertinoModalPopup(
          context: context,
          builder: (context) => CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _showEditTitleDialog(context, session, chatProvider);
                },
                child: const Text('이름 변경'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _shareSession(context, session);
                },
                child: const Text('공유하기'),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context, session, chatProvider);
                },
                child: const Text('삭제하기'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
          ),
        );
      },
    );
  }

  void _showEditTitleDialog(
    BuildContext context,
    ChatSession session,
    ChatProvider chatProvider,
  ) {
    final textController = TextEditingController(text: session.title);
    final isDarkMode = AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('대화 이름 변경'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: CupertinoTextField(
            controller: textController,
            autofocus: true,
            placeholder: '대화 이름을 입력하세요',
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Color(0xFF2A2B32) : CupertinoColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              final newTitle = textController.text.trim();
              if (newTitle.isNotEmpty && session.id != null) {
                chatProvider.updateSessionTitle(session.id!, newTitle);
              }
              Navigator.pop(context);
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareSession(BuildContext context, ChatSession session) async {
    // 대화 내용을 텍스트로 변환
    final buffer = StringBuffer();
    buffer.writeln('${session.title}\n');
    buffer.writeln('대화 일시: ${_getFormattedDate(session.createdAt)}\n');
    
    for (final message in session.messages) {
      final prefix = message.isUser ? '사용자: ' : '챗봇: ';
      buffer.writeln('$prefix${message.text}\n');
    }
    
    // 클립보드에 복사
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    // 사용자에게 복사 완료 알림
    if (context.mounted) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('클립보드에 복사됨'),
          message: const Text('대화 내용이 클립보드에 복사되었습니다.'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    ChatSession session,
    ChatProvider chatProvider,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('대화 삭제'),
        content: const Text('이 대화를 삭제하시겠습니까?\n삭제된 대화는 복구할 수 없습니다.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              if (session.id != null) {
                chatProvider.deleteSession(session.id!);
              }
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDarkMode) {
    final textColor = isDarkMode 
        ? AppTheme.darkTextSecondary 
        : AppTheme.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.transparent,
                backgroundImage: const AssetImage('assets/chatgpt_logo.png'),
                onBackgroundImageError: (_, __) {
                  // 이미지 로드 실패 시 기본 아이콘 표시
                },
                child: Icon(
                  CupertinoIcons.chat_bubble_2_fill,
                  color: AppTheme.darkPrimary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '보험 GA 챗봇',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '© 2024 보험 GA 챗봇 | 모든 권한 보유',
            style: TextStyle(
              color: textColor.withOpacity(0.6),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getFormattedDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (date == today) {
      // 오늘인 경우 시간만 표시
      return '오늘 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (date == today.subtract(const Duration(days: 1))) {
      // 어제인 경우
      return '어제';
    } else {
      // 그 외의 경우 날짜 표시
      return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
} 