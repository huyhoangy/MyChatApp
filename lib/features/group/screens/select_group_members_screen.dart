import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/user_model.dart';
import 'create_group_screen.dart';

class SelectGroupMembersScreen extends StatefulWidget {
  const SelectGroupMembersScreen({Key? key}) : super(key: key);

  @override
  State<SelectGroupMembersScreen> createState() =>
      _SelectGroupMembersScreenState();
}

class _SelectGroupMembersScreenState extends State<SelectGroupMembersScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<UserModel> _selectedFriends = [];

  void _toggleFriendSelection(UserModel friend) {
    setState(() {
      if (_selectedFriends.any((user) => user.uid == friend.uid)) {
        _selectedFriends.removeWhere((user) => user.uid == friend.uid);
      } else {
        _selectedFriends.add(friend);
      }
    });
  }

  void _goToCreateGroupScreen() {
    if (_selectedFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một người bạn.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateGroupScreen(
          selectedMembers: _selectedFriends,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserUid = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chọn thành viên (${_selectedFriends.length})'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _goToCreateGroupScreen,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(currentUserUid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          List<dynamic> friendUids = (snapshot.data!.data() as Map<String, dynamic>)
              .containsKey('friends')
              ? snapshot.data!.get('friends')
              : [];

          if (friendUids.isEmpty) {
            return const Center(child: Text('Bạn chưa có bạn bè nào.'));
          }

          return FutureBuilder<List<UserModel>>(
            future: _getFriendsDetails(friendUids),
            builder: (context, friendsSnapshot) {
              if (!friendsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final friends = friendsSnapshot.data!;

              return ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  final isSelected = _selectedFriends.any((user) => user.uid == friend.uid);

                  return CheckboxListTile(
                    title: Text(friend.displayName),
                    subtitle: Text(friend.email),
                    secondary: CircleAvatar(
                      backgroundImage: (friend.photoUrl.isNotEmpty)
                          ? NetworkImage(friend.photoUrl)
                          : null,
                      child: (friend.photoUrl.isEmpty)
                          ? Text(friend.displayName[0].toUpperCase())
                          : null,
                    ),
                    value: isSelected,
                    onChanged: (bool? value) {
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

  Future<List<UserModel>> _getFriendsDetails(List<dynamic> friendUids) async {
    List<UserModel> friends = [];
    for (String uid in friendUids) {
      final doc = await _firestore.collection('users').doc(uid).get();
      friends.add(UserModel.fromFirestore(doc));
    }
    return friends;
  }
}