import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/message_model.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  final String receiverUid;
  final String receiverName;
  final bool isGroup;

  const ChatScreen({
    Key? key,
    required this.receiverUid,
    required this.receiverName,
    this.isGroup = false, // Mặc định là false (chat 1-1)
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _currentUserUid;
  late String _chatRoomId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentUserUid = _auth.currentUser!.uid;

    if (widget.isGroup) {
      _chatRoomId = widget.receiverUid;
    } else {
      _chatRoomId = _getChatRoomId(_currentUserUid, widget.receiverUid);
    }
  }

  String _getChatRoomId(String uid1, String uid2) {
    if (uid1.hashCode <= uid2.hashCode) {
      return '${uid1}_${uid2}';
    } else {
      return '${uid2}_${uid1}';
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    final Timestamp timestamp = Timestamp.now();

    Map<String, dynamic> messageData = {
      'text': text.trim(),
      'senderUid': _currentUserUid,
      'receiverUid': widget.receiverUid,
      'timestamp': timestamp,
      'isRecalled': false,
    };

    try {
      await _firestore
          .collection('chat_rooms')
          .doc(_chatRoomId)
          .collection('messages')
          .add(messageData);

      await _firestore.collection('chat_rooms').doc(_chatRoomId).set(
        {
          'lastMessage': text.trim(),
          'lastTimestamp': timestamp,
          if (!widget.isGroup) 'users': [_currentUserUid, widget.receiverUid],
        },
        SetOptions(merge: true),
      );

      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi tin nhắn: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _recallMessage(String messageId) async {
    try {
      await _firestore
          .collection('chat_rooms')
          .doc(_chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'text': 'Tin nhắn đã được thu hồi',
        'isRecalled': true,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi thu hồi: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRecallDialog(String messageId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thu hồi tin nhắn?'),
        content: const Text('Tin nhắn này sẽ được thu hồi cho tất cả mọi người trong đoạn chat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _recallMessage(messageId);
            },
            child: const Text('Thu hồi', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage('https://placehold.co/600x1200/e8e0d4/e8e0d4?text=Chat+Background'),
            fit: BoxFit.cover,
            opacity: 0.5,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chat_rooms')
                    .doc(_chatRoomId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.teal));
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Đã xảy ra lỗi.', style: TextStyle(color: Colors.red)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Hãy gửi tin nhắn đầu tiên!'));
                  }

                  final messagesDocs = snapshot.data!.docs;

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(10.0),
                    itemCount: messagesDocs.length,
                    itemBuilder: (context, index) {
                      final doc = messagesDocs[index];
                      final messageData = doc.data() as Map<String, dynamic>;

                      final message = Message(
                        id: doc.id,
                        text: messageData['text'] ?? '',
                        senderId: messageData['senderUid'] ?? '',
                        timestamp: (messageData['timestamp'] as Timestamp).toDate(),
                        isRecalled: messageData['isRecalled'] ?? false,
                      );

                      final isMe = message.senderId == _currentUserUid;

                      return GestureDetector(
                        onLongPress: () {
                          if (isMe && !message.isRecalled) {
                            _showRecallDialog(message.id);
                          }
                        },
                        child: ChatBubble(message: message, isMe: isMe),
                      );
                    },
                  );
                },
              ),
            ),
            MessageInput(onSendPressed: _sendMessage),
          ],
        ),
      ),
    );
  }
}