import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/user_model.dart';

class AddMembersScreen extends StatefulWidget {
  final String chatRoomId;
  final List<dynamic> currentMembersUids;
  const AddMembersScreen({Key? key, required this.chatRoomId,
    required this.currentMembersUids}) : super(key: key);
  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<UserModel> _selectedFriends =[];
  bool _isLoading = false;
  void _toggleFriendSelection(UserModel friend){
    setState(() {
      if (_selectedFriends.any((user) => user.uid == friend.uid)) {
        _selectedFriends.removeWhere((user) => user.uid == friend.uid);
      } else {
        _selectedFriends.add(friend);
      }
    });
  }
  Future<void> _addMembersToGroup() async{
    if(_selectedFriends.isEmpty)
      return;
    setState(() {
      _isLoading = true;
    });
    try{
      List<String> newMemberUids = _selectedFriends.map((user)=>user.uid).toList();
      await _firestore.collection('chat_rooms').doc(widget.chatRoomId).update({
        'users' :FieldValue.arrayUnion(newMemberUids),
      });
      String newNames = _selectedFriends.map((u)=>u.displayName).join(",");
      await _firestore.collection('chat_rooms').doc(widget.chatRoomId).collection('messages').add({
        'text': '$newNames đã được thêm vào nhóm',
        'senderUid': 'system',
        'timestamp':FieldValue.serverTimestamp(),
      });
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch(e){
      if(mounted){
        setState(() {
          _isLoading=false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Future<List<UserModel>> _getAvailableFriends(List<dynamic> friendUids) async{
    List<UserModel> availableFriends =[];
    for(String uid in friendUids){
      if(!widget.currentMembersUids.contains(uid)){
        final doc = await _firestore.collection('users').doc(uid).get();
        availableFriends.add(UserModel.fromFirestore(doc));
      }
    }
    return availableFriends;
  }
  @override
  Widget build(BuildContext context) {
    final String currentUserUid = _auth.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: Text('Thêm thành viên (${_selectedFriends.length})'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check),
            onPressed: _isLoading || _selectedFriends.isEmpty ? null : _addMembersToGroup,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(currentUserUid).snapshots(),
        builder: (context,snapshot){
          if(!snapshot.hasData)
            return const Center(
              child: CircularProgressIndicator(),
            );
          List<dynamic> friendUids = (snapshot.data!.data() as Map<String,dynamic>).containsKey('friends')
          ? snapshot.data!.get('friends'):[];
          if(friendUids.isEmpty)
            return const Center(
              child: Text('Không có bạn bè để thêm'),
            );
          return FutureBuilder<List<UserModel>>(
            future: _getAvailableFriends(friendUids),
            builder: (context,friendsSnapshot){
              if(friendsSnapshot.connectionState == ConnectionState.waiting){
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.teal,
                  ),
                );
              }
              final friends =friendsSnapshot.data ??[];
              if(friends.isEmpty){
                return const Center(
                  child: Text('Tất cả bạn bè đã được thêm'),
                );
              }
              return ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context,index){
                  final friend =friends[index];
                  final isSelected =_selectedFriends.any((user) =>user.uid==friend.uid);
                  return CheckboxListTile(
                    title: Text(friend.displayName),
                    subtitle: Text(friend.email),
                    secondary: CircleAvatar(
                      backgroundImage: (friend.photoUrl.isNotEmpty) ?NetworkImage(friend.photoUrl):null,
                      child: (friend.photoUrl.isEmpty) ? Text(friend.displayName[0].toUpperCase()) : null,
                    ),
                    value: isSelected,
                    activeColor: Colors.teal,
                    onChanged: (bool ? value){
                      _toggleFriendSelection(friend);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}