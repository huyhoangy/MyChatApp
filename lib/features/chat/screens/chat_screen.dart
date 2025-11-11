import 'package:flutter/material.dart';
import '../../../core/models/message_model.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ID giả lập cho 2 người dùng
  final String _myId = 'user1';
  final String _otherUserId = 'user2';

  // Danh sách tin nhắn giả lập (MOCK DATA)
  final List<Message> _mockMessages = [
    Message(
        id: '1',
        text: 'Chào bạn, bạn khoẻ không?',
        senderId: 'user2',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
    Message(
        id: '2',
        text: 'Tôi khoẻ, cảm ơn bạn. Còn bạn?',
        senderId: 'user1',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4))),
    Message(
        id: '3',
        text: 'Tôi cũng khoẻ. Đang làm gì đó?',
        senderId: 'user2',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2))),
  ];

  final ScrollController _scrollController = ScrollController();

  // Hàm này xử lý việc gửi tin nhắn (thêm vào list)
  void _sendMessage(String text) {
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      senderId: _myId, // Giả lập là tôi gửi
      timestamp: DateTime.now(),
    );

    setState(() {
      _mockMessages.add(newMessage);
    });

    // Tự động cuộn xuống tin nhắn mới nhất
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tên Người Nhận'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
                'https://placehold.co/600x1200/e8e0d4/e8e0d4?text=Chat+Background'),
            fit: BoxFit.cover,
            opacity: 0.5,
          ),
        ),
        child: Column(
          children: [
            // Khu vực hiển thị tin nhắn
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(10.0),
                itemCount: _mockMessages.length,
                itemBuilder: (context, index) {
                  final message = _mockMessages[index];
                  final isMe = message.senderId == _myId;
                  return ChatBubble(message: message, isMe: isMe);
                },
              ),
            ),
            // Khu vực nhập liệu
            MessageInput(onSendPressed: _sendMessage),
          ],
        ),
      ),
    );
  }
}