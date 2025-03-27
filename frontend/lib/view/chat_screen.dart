import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  String _response = '';
  bool _isLoading = false;

  Future<void> _getResponse() async {
    setState(() {
      _isLoading = true;
    });
    final query = _controller.text;
    final url = Uri.parse('http://localhost:8000/search');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _response = data['answer'];
        });
      } else {
        setState(() {
          _response = '오류: 응답을 가져올 수 없습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _response = '오류: $e';
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
      appBar: AppBar(title: Text('보험 GA 챗봇')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(hintText: '질문을 입력하세요'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _getResponse,
              child: _isLoading ? CircularProgressIndicator() : Text('질문하기'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_response, style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}