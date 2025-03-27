import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isDarkMode;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bubbleColor = message.isUser 
        ? AppTheme.getUserBubbleColor(isDarkMode)
        : AppTheme.getBotBubbleColor(isDarkMode);
    
    final textColor = isDarkMode 
        ? AppTheme.darkTextPrimary 
        : AppTheme.lightTextPrimary;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) _buildAvatar(false),
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              margin: EdgeInsets.only(
                left: message.isUser ? 64.0 : 12.0,
                right: message.isUser ? 0.0 : 64.0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        message.isUser ? '사용자' : '보험 GA 챗봇',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: message.isUser 
                              ? AppTheme.lightPrimary 
                              : AppTheme.darkPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (!message.isUser)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          child: Icon(
                            CupertinoIcons.doc_on_doc,
                            color: textColor.withOpacity(0.6),
                            size: 16,
                          ),
                          onPressed: () => _copyText(context, message.text),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MarkdownBody(
                    data: message.text,
                    selectable: true,
                    onTapLink: (text, href, title) {
                      if (href != null) {
                        launchUrl(Uri.parse(href));
                      }
                    },
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.5,
                      ),
                      h1: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      h3: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      blockquote: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: isDarkMode 
                            ? Colors.grey[800]!.withOpacity(0.5)
                            : Colors.grey[200]!,
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border(
                          left: BorderSide(
                            color: isDarkMode 
                                ? AppTheme.darkPrimary
                                : AppTheme.lightPrimary,
                            width: 4.0,
                          ),
                        ),
                      ),
                      code: TextStyle(
                        color: textColor,
                        backgroundColor: isDarkMode 
                            ? Colors.grey[900]
                            : Colors.grey[200],
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: isDarkMode 
                            ? Colors.grey[900] 
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      tableHead: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      tableBody: TextStyle(
                        color: textColor,
                      ),
                      tableBorder: TableBorder.all(
                        color: isDarkMode 
                            ? Colors.grey[700]!
                            : Colors.grey[400]!,
                        width: 0.5,
                      ),
                      tableCellsPadding: const EdgeInsets.all(8.0),
                      listBullet: TextStyle(
                        color: textColor,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (message.isUser) _buildAvatar(true),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: isUser ? Colors.blue[100] : AppTheme.darkPrimary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          isUser 
              ? CupertinoIcons.person_fill
              : CupertinoIcons.chat_bubble_2_fill,
          color: isUser ? Colors.blue[800] : Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _copyText(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('복사 완료'),
        message: const Text('메시지가 클립보드에 복사되었습니다.'),
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