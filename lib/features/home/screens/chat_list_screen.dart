import 'package:flutter/material.dart';
import '../widgets/chat_list_item.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dữ liệu giả lập (MOCK DATA)
    final List<Map<String, String>> mockChats = [
      {
        "name": "Alice",
        "lastMessage": "Hẹn gặp bạn sau nhé!",
        "time": "10:30 Sáng",
        "imageUrl": "https://placehold.co/100x100/FFC107/FFFFFF?text=A"
      },
      {
        "name": "Bob",
        "lastMessage": "Ok, tôi sẽ gửi nó ngay.",
        "time": "Hôm qua",
        "imageUrl": "https://placehold.co/100x100/3F51B5/FFFFFF?text=B"
      },
      {
        "name": "Nhóm Lớp",
        "lastMessage": "Bạn: Đã hoàn thành bài tập.",
        "time": "08:15 Tối",
        "imageUrl": "https://placehold.co/100x100/4CAF50/FFFFFF?text=N"
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đoạn chat'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: xu ly tim kiem
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: mockChats.length,
        itemBuilder: (context, index) {
          final chat = mockChats[index];
          return ChatListItem(
            name: chat['name']!,
            lastMessage: chat['lastMessage']!,
            time: chat['time']!,
            imageUrl: chat['imageUrl']!,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Mở màn hình danh bạ để bắt đầu chat mới
        },
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
        child: const Icon(Icons.message_rounded),
      ),
    );
  }
}