import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String? nickname;
  final  bool isGroup;
  final String chatRoomId;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.nickname,
    this.isGroup=false,
    required this.chatRoomId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (message.senderId == 'system') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
          child: Text(message.text, style: const TextStyle(fontSize: 12, color: Colors.black54), textAlign: TextAlign.center),
        ),
      );
    }

    if (isMe) {
      return Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildMessageContainer(isMe: true),
              if(_isSeen())
                _buildSeenStatus(),
            ],
          ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(message.senderId).get(),
            builder: (context, snapshot) {
              Widget defaultAvatar = CircleAvatar(radius: 16, backgroundColor: Colors.grey[300], child: const Icon(Icons.person, size: 16, color: Colors.white));

              if (!snapshot.hasData || !snapshot.data!.exists) return defaultAvatar;

              var userData = snapshot.data!.data() as Map<String, dynamic>;
              String? photoUrl = userData['photoUrl'];
              String displayName = nickname ?? userData['displayName'] ?? '?';

              if (photoUrl != null && photoUrl.isNotEmpty) {
                return CircleAvatar(radius: 16, backgroundImage: NetworkImage(photoUrl));
              } else {
                return CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.teal[100],
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 12, color: Colors.teal[800], fontWeight: FontWeight.bold),
                  ),
                );
              }
            },
          ),

          const SizedBox(width: 8),

          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(message.senderId).get(),
                  builder: (context, snapshot) {
                    String displayName = '...';
                    if (nickname != null) {
                      displayName = nickname!;
                    } else if (snapshot.hasData && snapshot.data!.exists) {
                      var data = snapshot.data!.data() as Map<String, dynamic>;
                      displayName = data['displayName'] ?? 'Người lạ';
                    }

                    return Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
                      child: Text(
                        displayName,
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),

                _buildMessageContainer(isMe: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
  bool _isSeen(){
    return message.seenBy.length>1;
  }
  Widget _buildSeenStatus(){
    if(!isGroup){
      return const Padding(
        padding: EdgeInsets.only(top: 2.0,right: 8.0),
        child: Text(
          'Đã xem ',
          style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }
    List<dynamic> viewerUids = List.from(message.seenBy);
    viewerUids.remove(message.senderId);
    if(viewerUids.isEmpty)
      return const SizedBox.shrink();
    return FutureBuilder<List<String>>(
      future: _fetchViewerNames(viewerUids),
      builder: (context,snapshot){
        String text ='Đã xem';
        if(snapshot.hasData && snapshot.data!.isNotEmpty){
          text = 'Đã xem bởi: ${snapshot.data!.join(', ')}';
        }
        return Padding(
          padding: const EdgeInsets.only(top: 2.0,right: 8.0),
          child: Text(
            text,
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
          ),

        );
      },
    );
  }
  Future<List<String>> _fetchViewerNames(List<dynamic> uids) async {
    List<String> names = [];
    try {
      var roomDoc = await FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId).get();
      Map<String, dynamic> nicknamesMap = {};
      if (roomDoc.exists && roomDoc.data()!.containsKey('nicknames')) {
        nicknamesMap = roomDoc.data()!['nicknames'];
      }

      for (String uid in uids) {
        if (nicknamesMap.containsKey(uid)) {
          names.add(nicknamesMap[uid]);
        } else {
          var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (userDoc.exists) {
            names.add(userDoc.data()!['displayName'] ?? 'Người dùng');
          }
        }
      }
    } catch (e) {
    }
    return names;
  }

  Widget _buildMessageContainer({required bool isMe}) {
    // Kiểm tra nếu đây là tin nhắn CHỈ CÓ ẢNH (và không có text)
    bool isImageOnly = (message.imageUrl != null && message.imageUrl!.isNotEmpty) &&
        (message.text.isEmpty || message.text == ''); // Text rỗng hoặc chỉ là dấu cách

    return Container(
      margin: isMe ? const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0) : EdgeInsets.zero,
      padding: isImageOnly ? const EdgeInsets.all(8.0) : const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0), // <--- SỬA DÒNG NÀY
      decoration: BoxDecoration(
        color: isMe ? Colors.teal[300] : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18.0),
          topRight: const Radius.circular(18.0),
          bottomLeft: isMe ? const Radius.circular(18.0) : const Radius.circular(0),
          bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(18.0),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 3)],
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.imageUrl != null && message.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: CachedNetworkImage(
                imageUrl: message.imageUrl!,
                placeholder: (context, url) => Container(
                  width: 200,
                  height: 150,
                  color: Colors.grey[200],
                  child: Center(child: CircularProgressIndicator(color: Colors.teal)),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 200,
                  height: 150,
                  color: Colors.grey[200],
                  child: Center(child: Icon(Icons.error, color: Colors.red)),
                ),
                width: 200,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            // Chỉ thêm khoảng cách nếu có text đi kèm
            if (!message.isRecalled && (message.text.isNotEmpty && message.text != ''))
              const SizedBox(height: 8.0),
          ],

          // Hiển thị text chỉ khi không phải là tin nhắn thu hồi VÀ có text thật sự
          if (!message.isRecalled && (message.text.isNotEmpty && message.text != ''))
            Text(
              message.text,
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.black87,
              ),
            ),
          // Nếu là tin nhắn thu hồi
          if (message.isRecalled)
            Text(
              'Tin nhắn đã được thu hồi',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.black87,
                fontStyle: FontStyle.italic,
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.black54,
              ),
            ),
          const SizedBox(height: 4.0),
          Text(
            '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 10.0, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}