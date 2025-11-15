import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/message_model.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  final String receiverUid;
  final String receiverName;

  const ChatScreen({
    Key? key,
    required this.receiverUid,
    required this.receiverName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _currentUserUid; // ID của người dùng hiện tại
  late String _chatRoomId; // ID của phòng chat

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentUserUid = _auth.currentUser!.uid;
    _chatRoomId = _getChatRoomId(_currentUserUid, widget.receiverUid);
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
    };

    try {
      await _firestore
          .collection('chat_rooms')
          .doc(_chatRoomId)
          .collection('messages')
          .add(messageData);

      await _firestore.collection('chat_rooms').doc(_chatRoomId).set(
        {
          'users': [_currentUserUid, widget.receiverUid],
          'lastMessage': text.trim(),
          'lastTimestamp': timestamp,
        },
        SetOptions(merge: true), // 'merge: true' sẽ tạo mới nếu chưa có, hoặc cập nhật nếu đã có
      );

      _scrollController.animateTo(
        0, // Cuộn lên đầu (vì danh sách bị đảo ngược)
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi tin nhắn: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }
  Future<void> _recallMessage(String messageId) async{
    try{
      await _firestore.collection('chat_rooms')
          .doc(_chatRoomId).collection('messages').doc(messageId).update({
        'text':'Tin nhắn đã được thu hồi',
        'isRecalled':true,
      });
      // (Tùy chọn) Cập nhật luôn lastMessage của phòng chat
      // nếu tin nhắn bị thu hồi là tin nhắn cuối cùng
      // (Phần này nâng cao, có thể bỏ qua)
    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi thu hồi tin nhắn: ${e.toString()}'),backgroundColor: Colors.red,),
      );
    }
  }
  void _showRecallDialog(String messageId){
    showDialog(
      context: context,
      builder: (ctx)=>AlertDialog(
        title: const Text('Thu hồi tin nhắn'),
        content: const Text('Bạn có chắc chắn muốn thu hồi tin nhắn này?'),
        actions: [
          TextButton(
            onPressed: () =>Navigator.of(ctx).pop(), // nut huy
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _recallMessage(messageId);
            },
            child: const Text('Thu hồi',style: TextStyle(color:Colors.red)),
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
                  // Lỗi
                  if (snapshot.hasError) {
                    return const Center(child: Text('Đã xảy ra lỗi.', style: TextStyle(color: Colors.red)));
                  }
                  // Không có tin nhắn
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Hãy gửi tin nhắn đầu tiên!'));
                  }

                  // Lấy danh sách tin nhắn thật
                  final messagesDocs = snapshot.data!.docs;
                  // Chuyển đổi dữ liệu Firestore (Map) thành đối tượng Message

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(10.0),
                    itemCount: messagesDocs.length,
                    itemBuilder: (context, index) {
                      final doc = messagesDocs[index];
                      final messageData = doc.data() as Map<String, dynamic>;
                      final message =Message(
                        id: doc.id,
                        text: messageData['text'] ?? '',
                        senderId: messageData['senderUid'] ?? '',
                        timestamp: (messageData['timestamp'] as Timestamp).toDate(),
                        isRecalled: messageData['isRecalled'] ?? false,
                      );


                      final isMe = message.senderId == _currentUserUid;
                      return GestureDetector(
                        onLongPress: () {
                          // chi cho phep thu hoi tin nhan cua minh
                          if(isMe && !message.isRecalled){
                            _showRecallDialog(message.id);

                          }
                        },
                        child: ChatBubble(message: message,isMe: isMe),
                      );

                      // return ChatBubble(message: message, isMe: isMe);
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