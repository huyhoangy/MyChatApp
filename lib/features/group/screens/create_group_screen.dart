import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/user_model.dart';
import '../../chat/screens/chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  final List<UserModel> selectedMembers;

  const CreateGroupScreen({
    Key? key,
    required this.selectedMembers,
  }) : super(key: key);

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _createGroupChat() async {
    final String groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên nhóm')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final String currentUserUid = _auth.currentUser!.uid;
      List<String> memberUids = widget.selectedMembers.map((user) => user.uid).toList();
      memberUids.add(currentUserUid);

      DocumentReference groupChatDoc = await _firestore.collection('chat_rooms').add({
        'groupName': groupName,
        'users': memberUids,
        'lastMessage': 'Nhóm đã được tạo',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'isGroup': true,
        'groupAdmin': currentUserUid,
      });

      await groupChatDoc.collection('messages').add({
        'text': '$groupName đã được tạo.',
        'senderUid': 'system',
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            receiverUid: groupChatDoc.id,
            receiverName: groupName,
            isGroup: true,
          ),
        ),
            (route) => route.isFirst,
      );

    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi tạo nhóm: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo nhóm mới'), backgroundColor: Colors.teal[700], foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(labelText: 'Tên nhóm', prefixIcon: Icon(Icons.group_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 20),
            const Text('Thành viên:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: widget.selectedMembers.length,
                itemBuilder: (context, index) {
                  final member = widget.selectedMembers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (member.photoUrl.isNotEmpty) ? NetworkImage(member.photoUrl) : null,
                      child: (member.photoUrl.isEmpty) ? Text(member.displayName[0].toUpperCase()) : null,
                    ),
                    title: Text(member.displayName),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _createGroupChat,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.check),
      ),
    );
  }
}