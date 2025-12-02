import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/message_model.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../../group/screens/add_members_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
class ChatScreen extends StatefulWidget {
  final String receiverUid;
  final String receiverName;
  final bool isGroup;

  const ChatScreen({
    Key? key,
    required this.receiverUid,
    required this.receiverName,
    this.isGroup = false,
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
  bool _isTypingLocal=false;

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

  Future<void> _updateNickname(String targetUid, String newName) async {
    try {
      if (widget.isGroup && targetUid == _chatRoomId) {
        await _firestore.collection('chat_rooms').doc(_chatRoomId).update({
          'groupName': newName,
        });
      } else {
        await _firestore.collection('chat_rooms').doc(_chatRoomId).set({
          'nicknames': {
            targetUid: newName
          }
        }, SetOptions(merge: true));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đặt tên thành công!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }
  void _markMessageAsSeen(String messageId,List<dynamic>seenBy){
    final String currentUserUid = _auth.currentUser!.uid;
    if(!seenBy.contains(currentUserUid)){
      _firestore.collection('chat_rooms')
          .doc(_chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({
        'seenBy':FieldValue.arrayUnion([currentUserUid]),
      });
    }
  }

  void _showEditNameDialog(String targetUid, String currentName, String label) {
    final TextEditingController _nicknameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: _nicknameController,
          decoration: const InputDecoration(
            labelText: 'Tên mới',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nicknameController.text.trim().isNotEmpty) {
                _updateNickname(targetUid, _nicknameController.text.trim());
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showParticipantsList() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('chat_rooms').doc(_chatRoomId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            var chatData = snapshot.data!.data() as Map<String, dynamic>;
            List<dynamic> userIds = chatData['users'] ?? [];
            Map<String, dynamic> nicknames = chatData['nicknames'] ?? {};
            String groupName = chatData['groupName'] ?? 'Nhóm';
            String ? groupIcon = chatData['groupIcon'];
            String groupAdmin = chatData['groupAdmin'] ?? '';
            bool iAmAdmin = (_currentUserUid ==groupAdmin);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    widget.isGroup ? 'Thông tin nhóm' : 'Đặt biệt danh',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),

                if (widget.isGroup)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal[100],
                      backgroundImage: (groupIcon != null&&groupIcon.isNotEmpty)?NetworkImage(groupIcon):null,
                      child: (groupIcon == null || groupIcon.isEmpty)
                          ? const Icon(Icons.groups, color: Colors.teal)
                          : null,
                    ),
                    title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Tên nhóm"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:  const Icon(Icons.camera_alt,color: Colors.teal) ,
                          onPressed: _changeGroupAvatar,
                          tooltip: 'Đổi ảnh nhóm',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.teal),
                          onPressed: (){
                            _showEditNameDialog(_chatRoomId, groupName, 'Đổi tên nhóm');
                          },
                          tooltip: 'Đổi tên nhóm',
                        ),
                      ],
                    ),

                  ),
                if (widget.isGroup) const Divider(height: 1),

                Expanded(
                  child: ListView.builder(
                    itemCount: userIds.length,
                    itemBuilder: (context, index) {
                      String uid = userIds[index];

                      return FutureBuilder<DocumentSnapshot>(
                        future: _firestore.collection('users').doc(uid).get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return const ListTile(title: Text('Đang tải...'));
                          }

                          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          String originalName = userData['displayName'] ?? 'Người dùng';
                          String photoUrl = userData['photoUrl'] ?? '';

                          String displayName = nicknames.containsKey(uid) ? nicknames[uid] : originalName;
                          String subtitle = (displayName != originalName) ? "Tên gốc: $originalName" : 'Chưa có biệt danh';
                          bool isMe = uid == _currentUserUid;
                          if(uid==groupAdmin){
                            subtitle = 'Quản trị viên';
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: (photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                              backgroundColor: Colors.teal[100],
                              child: (photoUrl.isEmpty) ? Text(originalName.isNotEmpty ? originalName[0].toUpperCase() : '?') : null,
                            ),
                            title: Text(
                              isMe ? '$displayName (Bạn)' : displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(subtitle, style: TextStyle(color: uid == groupAdmin ? Colors.teal : Colors.grey)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                                  onPressed: () => _showEditNameDialog(uid, displayName, 'Đặt biệt danh'),
                                ),
                                if(iAmAdmin && !isMe)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                    onPressed: () => _removeMember(uid, displayName),
                                  ),
                              ],
                            ),
                            onTap: () {
                              _showEditNameDialog(uid, displayName, 'Đặt biệt danh');
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  void _updateTypingToFirestore(bool isTyping){
    if(_isTypingLocal==isTyping) return;
    _isTypingLocal=isTyping;
    _firestore.collection('chat_rooms').doc(_chatRoomId).update({
      'typingUsers.$_currentUserUid': isTyping,
    });
  }
  Widget _buildTypingIndicator(){
    return StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('chat_rooms').doc(_chatRoomId).snapshots(),
        builder: (context,snapshot){
          if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
          var data =snapshot.data!.data() as Map<String,dynamic>;
          Map<String,dynamic> typingUsers ={};
          if(data.containsKey('typingUsers')){
            typingUsers =data['typingUsers'];
          }
          Map<String, dynamic> nicknames = {};
          if (data.containsKey('nicknames')) {
            nicknames = data['nicknames'];
          }

          List<String> typingNames = [];
          typingUsers.forEach((uid,isTyping){
            if(isTyping== true &&  uid!= _currentUserUid){
              String name ="Người dùng";
              if(nicknames.containsKey(uid)){
                name = nicknames[uid];
              }
              else{
                if(!widget.isGroup){
                  name = widget.receiverName;
                  if (nicknames.containsKey(uid)) name = nicknames[uid];
                } else {
                  name = "Thành viên";
                }
              }
              typingNames.add(name);
            }
          });
          if (typingNames.isEmpty) return const SizedBox.shrink();
          String text = typingNames.join(", ") + (typingNames.length > 1 ? " đang soạn tin..." : " đang soạn tin...");
          return Padding(
            padding: const EdgeInsets.only(left: 16.0,bottom: 4.0,top: 4.0),
            child: Row(
              children: [
                Container(
                  padding:const EdgeInsets.symmetric(horizontal: 10.0,vertical: 5.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 10,
                        height: 10,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal)
                      ),
                      const SizedBox(width: 8),
                      Text(
                        text,
                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  void _sendMessage(String text, {String? imageUrl}) async {
    if (text.trim().isEmpty && imageUrl == null) {
      return;
    }
    final Timestamp timestamp = Timestamp.now();

    Map<String, dynamic> messageData = {
      'text': text.trim(),
      'senderUid': _currentUserUid,
      'receiverUid': widget.receiverUid,
      'timestamp': timestamp,
      'isRecalled': false,
      'imageUrl': imageUrl,
      'seenBy':[_currentUserUid],
    };

    try {
      await _firestore.collection('chat_rooms').doc(_chatRoomId).collection('messages').add(messageData);

      String displayLastMessage = text.isNotEmpty ? text : (imageUrl != null ? 'Đã gửi ảnh' : '');
      if (displayLastMessage.isEmpty) displayLastMessage = 'Tin nhắn mới';

      await _firestore.collection('chat_rooms').doc(_chatRoomId).set({
        'lastMessage': displayLastMessage,
        'lastTimestamp': timestamp,
        'deletedBy':[],
        if (!widget.isGroup) 'users': [_currentUserUid, widget.receiverUid],
      }, SetOptions(merge: true));
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  Future<void> _recallMessage(String messageId) async {
    try {
      await _firestore.collection('chat_rooms').doc(_chatRoomId).collection('messages').doc(messageId).update({
        'text': 'Tin nhắn đã được thu hồi',
        'isRecalled': true,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  void _showRecallDialog(String messageId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thu hồi tin nhắn?'),
        content: const Text('Tin nhắn này sẽ được thu hồi cho tất cả mọi người.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
          TextButton(onPressed: () { Navigator.of(ctx).pop(); _recallMessage(messageId); }, child: const Text('Thu hồi', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
  Future<void>_removeMember(String memberUid, String memberName) async{
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa thành viên?'),
        content: Text('Bạn có chắc chắn muốn xóa $memberName khỏi nhóm?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),

        ],
      ),
    ) ?? false ;
    if(!confirm) return ;
      try{
        await _firestore.collection('chat_rooms').doc(_chatRoomId).update({
          'users':FieldValue.arrayRemove([memberUid]),
        });
        await _firestore.collection('chat_rooms').doc(_chatRoomId).collection('messages').add({
          'text': '$memberName đã bị xóa khỏi nhóm',
          'senderUid': 'system',
          'timestamp':FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa thành viên.'), backgroundColor: Colors.green));
      } catch(e){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red));
      }
  }
  Future<void>_changeGroupAvatar() async{
    final ImagePicker picker =ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if(image == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang tải ảnh lên...'), backgroundColor: Colors.teal),
    );
    try{
      final cloudinary =CloudinaryPublic(
        'dtcxoncos','flutter_uploads_chatapp' ,cache: false
      );
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
          folder:'group_avatars_chatApp',
        ),
      );
      String newGroupIconUrl = response.secureUrl;
      await _firestore.collection('chat_rooms').doc(_chatRoomId).update({
        'groupIcon':newGroupIconUrl,
      });
      await _firestore.collection('chat_rooms').doc(_chatRoomId).collection('messages').add({
        'text': 'Đã thay đổi ảnh đại diện nhóm',
        'senderUid': 'system',
        'timestamp':FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thay đổi ảnh nhóm'),backgroundColor: Colors.green),
      );
    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('chat_rooms').doc(_chatRoomId).snapshots(),
          builder: (context, snapshot) {
            String displayName = widget.receiverName;
            List<dynamic> currentMembers=[];

            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              currentMembers = data['users'] ?? [];

              if (widget.isGroup) {
                displayName = data['groupName'] ?? widget.receiverName;
              } else {
                if (data.containsKey('nicknames')) {
                  var nicknames = data['nicknames'] as Map<String, dynamic>;
                  if (nicknames.containsKey(widget.receiverUid)) {
                    displayName = nicknames[widget.receiverUid];
                  }
                }
              }
            }
            return Text(displayName);
          },
        ),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,

        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('chat_rooms').doc(_chatRoomId).snapshots(),
            builder: (context,snapshot){
              List<dynamic> currentMembers =[];
              if(snapshot.hasData&& snapshot.data!.exists){
                var data = snapshot.data!.data() as Map<String,dynamic>;
                currentMembers = data ['users'] ??[];
              }
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'nicknames') {
                    _showParticipantsList();
                  }
                  else if( value== 'add_member'){
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder:(context)=>AddMembersScreen(
                              chatRoomId: _chatRoomId,
                              currentMembersUids: currentMembers),
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    if(widget.isGroup)
                      const PopupMenuItem<String>(
                        value: 'add_member',
                        child: Row(
                          children: [
                            Icon(Icons.person_add, color: Colors.teal, size: 20),
                            SizedBox(width: 10),
                            Text('Thêm thành viên'),
                          ],
                        ),
                      ),
                    PopupMenuItem<String>(
                      value: 'nicknames',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.teal, size: 20),
                          SizedBox(width: 10),
                          Text(widget.isGroup ? 'Đổi tên nhóm' : 'Đặt biệt danh'),                        ],
                      ),
                    ),
                  ];
                },
              );

            },
          ),
        ],
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
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('chat_rooms').doc(_chatRoomId).snapshots(),
                builder: (context, roomSnapshot) {
                  Timestamp clearHistoryTimestamp = Timestamp.fromMillisecondsSinceEpoch(0);
                  Map<String, dynamic> nicknames = {};
                  if (roomSnapshot.hasData && roomSnapshot.data!.exists) {
                    var data = roomSnapshot.data!.data() as Map<String, dynamic>;
                    if (data.containsKey('nicknames')) {
                      nicknames = data['nicknames'];
                    }
                    if(data.containsKey('historyClearedAt')){
                      var historyMap = data['historyClearedAt'] as Map<String, dynamic>;
                      if(historyMap.containsKey(_currentUserUid)){
                        clearHistoryTimestamp = historyMap[_currentUserUid] as Timestamp;
                      }
                    }
                  }
                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('chat_rooms')
                        .doc(_chatRoomId)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .endBefore([clearHistoryTimestamp])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const Center(child: CircularProgressIndicator(color: Colors.teal));
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                        return const Center(child: Text('Không có tin nhắn nào'));

                      final messagesDocs = snapshot.data!.docs;

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(10.0),
                        itemCount: messagesDocs.length,
                        itemBuilder: (context, index) {
                          final doc = messagesDocs[index];

                          final message = Message.fromFirestore(doc);

                          final isMe = message.senderId == _currentUserUid;
                          if(!isMe){
                            _markMessageAsSeen(message.id,message.seenBy);
                          }
                          String? senderNickname;
                          if (nicknames.containsKey(message.senderId)) {
                            senderNickname = nicknames[message.senderId];
                          }


                          return GestureDetector(
                            onLongPress: () {
                              if (isMe && !message.isRecalled) {
                                _showRecallDialog(message.id);
                              }
                            },
                            child: ChatBubble(
                              message: message,
                              isMe: isMe,
                              nickname: senderNickname,
                              isGroup: widget.isGroup,
                              chatRoomId: _chatRoomId,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            _buildTypingIndicator(),
            MessageInput(
                onSendPressed: (text, {imageUrl}) {
                  _sendMessage(text, imageUrl: imageUrl);
                },
                onTypingStatusChanged:(isTyping){
                  _updateTypingToFirestore(isTyping);
                },
            ),
          ],
        ),
      ),
    );
  }
}