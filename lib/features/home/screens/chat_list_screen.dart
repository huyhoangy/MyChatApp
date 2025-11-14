import 'package:flutter/material.dart';
import '../widgets/chat_list_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Gói định dạng ngày giờ
import '../../chat/screens/chat_screen.dart';
import '../../chat/screens/chat_screen.dart'; // Màn hình chat chi tiết
import '../../friend/screens/friend_list_screen.dart';
import '../../friend/screens/friend_list_screen.dart';
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);
  @override
  _ChatListScreenState createState() => _ChatListScreenState();

}
class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseAuth _auth =FirebaseAuth.instance;
  final FirebaseFirestore _firestore =FirebaseFirestore.instance;
  String ?_currentUserUid;
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState(){
    super.initState();
    _getCurrentUser();
    _searchController.addListener((){
      setState(() {
        _searchQuery =_searchController.text;
      });
    });
  }
  @override
  void dispose(){
    _searchController.dispose();
    super.dispose();
  }
  void _getCurrentUser(){
    setState(() {
      _currentUserUid = _auth.currentUser?.uid;
      _isLoading = false;
    });
  }
  String _formatTimestamp(Timestamp timestamp){
    DateTime dt=timestamp.toDate();
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));
    if(dt.isAfter(today)){
      return DateFormat('HH:mm').format(dt);
    } else if(dt.isAfter(yesterday)){
      return 'Hôm qua';
    }else{
      return DateFormat('dd/MM/yyyy').format(dt);
    }
  }
  AppBar _buildAppBar(){
    if(_isSearching){
      return AppBar(
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: (){
            setState(() {
              _isSearching =false;
              _searchController.clear();
            });
            FocusScope.of(context).unfocus();
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white,fontSize: 18),
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
        ),
      );
    } else {
      return AppBar(
        title: const Text('Đoạn chat'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () =>{
              setState(() {
                _isSearching =true;
              }),
            },
          ),
        ],
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          :_buildChatList(),
      floatingActionButton: FloatingActionButton(
          onPressed:() {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const FriendListScreen(),
            ));
          },
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
        child: const Icon(Icons.message_rounded),
      ),
    );

  }
  Widget _buildChatList(){
    if(_currentUserUid == null){
      return const Center(
        child: Text('Không thể tải người dùng'),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('chat_rooms')
      .where('users',arrayContains: _currentUserUid)
      .orderBy('lastTimestamp',descending: true)
      .snapshots(),
      builder: (context, snapshot){
        if(snapshot.connectionState == ConnectionState.waiting){
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        }
        if(snapshot.hasError){
          return const Center(
            child: Text('Đã xảy ra lỗi', style: TextStyle(color: Colors.red)),
          );
        }
        if(!snapshot.hasData || snapshot.data!.docs.isEmpty){
          return const Center(
            child: Text('Không có đoạn chat nào'),
          );
        }
        final chatRooms =snapshot.data!.docs;
        return ListView.builder(
          itemCount:chatRooms.length,
          itemBuilder: (context,index){
            var roomData = chatRooms[index].data() as Map<String,dynamic>;
            List <dynamic> users = roomData['users'];
            String otherUserUid = users.firstWhere((uid)=>uid != _currentUserUid);
            String lastMessage =roomData['lastMessage']??'';
            Timestamp lastTimestamp = roomData['lastTimestamp'] ?? Timestamp.now();
            String time = _formatTimestamp(lastTimestamp);
            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(otherUserUid).get(),
              builder: (context,userSnapshot){
                if(!userSnapshot.hasData){
                  return ListTile(
                    title: const Text('Đang tải...'),
                    subtitle: Text(lastMessage,maxLines: 1,overflow: TextOverflow.ellipsis),
                  );
                }
                var  userData = userSnapshot.data!.data() as Map<String,dynamic>;
                String name = userData['displayName'] ?? 'Người dùng';
                String placeholderInitial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                final bool matchesSearch = _searchQuery.isEmpty ||
                    name.toLowerCase().contains(_searchQuery.toLowerCase());
                if(!matchesSearch){
                  return const SizedBox.shrink();
                }
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0,vertical:8.0),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.teal[100],
                    backgroundImage: (userData['photoUrl'] != null && userData['photoUrl'].isNotEmpty)
                    ?NetworkImage(userData['photoUrl']!):null,
                    child: (userData['photoUrl']==null || userData['photoUrl'].isEmpty)
                    ?Text(
                      placeholderInitial,
                      style: TextStyle(color: Colors.teal[800],fontSize: 24,fontWeight: FontWeight.bold),
                    ): null
                  ),
                  title: Text(name,style: const TextStyle(fontWeight: FontWeight.bold),),
                  subtitle: Text(lastMessage,maxLines: 1,overflow: TextOverflow.ellipsis),
                  trailing: Text(time, style: const TextStyle(color: Colors.grey,fontSize: 12)),
                  onTap: (){
                    Navigator.push(context,MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        receiverUid: otherUserUid,
                        receiverName: name,
                      ),
                    ));
                  },
                );
                },
            );

          },
        );
      },
    );
  }
}