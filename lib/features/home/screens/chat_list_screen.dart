import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../chat/screens/chat_screen.dart';
import '../../friend/screens/friend_list_screen.dart';
import '../../group/screens/select_group_members_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _currentUserUid;
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _getCurrentUser() {
    setState(() {
      _currentUserUid = _auth.currentUser?.uid;
      _isLoading = false;
    });
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dt = timestamp.toDate();
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));

    if (dt.isAfter(today)) return DateFormat('HH:mm').format(dt);
    if (dt.isAfter(yesterday)) return 'Hôm qua';
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  Future<void> _deleteChat(String chatRoomId) async {
    try {
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'deletedBy': FieldValue.arrayUnion([_currentUserUid]),
        'historyClearedAt.$_currentUserUid': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa cuộc trò chuyện'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  AppBar _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() { _isSearching = false; _searchController.clear(); });
            FocusScope.of(context).unfocus();
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: const InputDecoration(hintText: 'Tìm kiếm...', hintStyle: TextStyle(color: Colors.white54), border: InputBorder.none),
        ),
      );
    } else {
      return AppBar(
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.group_add_rounded, size: 28),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SelectGroupMembersScreen()));
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () { setState(() { _isSearching = true; }); }),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: Colors.teal)) : _buildChatList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const FriendListScreen()));
        },
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
        child: const Icon(Icons.message_rounded),
      ),
    );
  }

  Widget _buildChatList() {
    if (_currentUserUid == null) return const Center(child: Text('Không thể tải người dùng.'));

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('chat_rooms').where('users', arrayContains: _currentUserUid).orderBy('lastTimestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.teal));
        if (snapshot.hasError) return const Center(child: Text('Đã xảy ra lỗi tải dữ liệu.'));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Chưa có cuộc trò chuyện nào.'));

        final chatRooms = snapshot.data!.docs;

        return ListView.builder(
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            var roomData = chatRooms[index].data() as Map<String, dynamic>;
            String chatRoomId = chatRooms[index].id;

            // --- 2. SỬA LỖI TẠI ĐÂY: Kiểm tra danh sách đã xóa ---
            List<dynamic> deletedBy = [];
            if (roomData.containsKey('deletedBy')) {
              deletedBy = roomData['deletedBy'];
            }
            // Nếu ID của mình nằm trong danh sách 'deletedBy', ẩn nó đi
            if (deletedBy.contains(_currentUserUid)) {
              return const SizedBox.shrink();
            }
            // --- KẾT THÚC SỬA LỖI ---

            bool isGroup = roomData['isGroup'] == true;
            String lastMessage = roomData['lastMessage'] ?? '';
            Timestamp lastTimestamp = roomData['lastTimestamp'] ?? Timestamp.now();
            String time = _formatTimestamp(lastTimestamp);

            // --- PHẦN DƯỚI GIỮ NGUYÊN ---
            if (isGroup) {
              String groupName = roomData['groupName'] ?? 'Nhóm không tên';
              if (_isSearching && !groupName.toLowerCase().contains(_searchQuery.toLowerCase())) return const SizedBox.shrink();

              return Dismissible(
                key: Key(chatRoomId),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) => _deleteChat(chatRoomId),
                background: Container(color: Colors.red[600], alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20.0), child: const Icon(Icons.delete_sweep_rounded, color: Colors.white)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.teal[100],
                    child: const Icon(Icons.groups_rounded, color: Colors.teal, size: 30),
                  ),
                  title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        receiverUid: chatRoomId,
                        receiverName: groupName,
                        isGroup: true,
                      ),
                    ));
                  },
                ),
              );
            } else {
              List<dynamic> users = roomData['users'];
              String otherUserUid = users.firstWhere((uid) => uid != _currentUserUid, orElse: () => "");

              // Lấy biệt danh (nếu có) để hiển thị ở danh sách
              Map<String, dynamic> nicknames = {};
              if (roomData.containsKey('nicknames')) {
                nicknames = roomData['nicknames'];
              }
              String? customNickname;
              if (nicknames.containsKey(otherUserUid)) {
                customNickname = nicknames[otherUserUid];
              }

              return Dismissible(
                key: Key(chatRoomId),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) => _deleteChat(chatRoomId),
                background: Container(color: Colors.red[600], alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20.0), child: const Icon(Icons.delete_sweep_rounded, color: Colors.white)),
                child: FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(otherUserUid).get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      // Hiển thị tạm nếu đang load user nhưng đã có biệt danh
                      return ListTile(title: Text(customNickname ?? 'Đang tải...'), subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis));
                    }
                    var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    if (userData == null) return const SizedBox.shrink();

                    String originalName = userData['displayName'] ?? 'Người dùng';
                    String nameToShow = customNickname ?? originalName; // Ưu tiên biệt danh

                    String placeholderInitial = nameToShow.isNotEmpty ? nameToShow[0].toUpperCase() : '?';
                    final bool matchesSearch = _searchQuery.isEmpty || nameToShow.toLowerCase().contains(_searchQuery.toLowerCase());
                    if (!matchesSearch) return const SizedBox.shrink();

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.teal[100],
                        backgroundImage: (userData['photoUrl'] != null && userData['photoUrl'].isNotEmpty) ? NetworkImage(userData['photoUrl']) : null,
                        child: (userData['photoUrl'] == null || userData['photoUrl'].isEmpty) ? Text(placeholderInitial, style: TextStyle(color: Colors.teal[800], fontSize: 24, fontWeight: FontWeight.bold)) : null,
                      ),
                      title: Text(nameToShow, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            receiverUid: otherUserUid,
                            receiverName: originalName,
                            isGroup: false,
                          ),
                        ));
                      },
                    );
                  },
                ),
              );
            }
          },
        );
      },
    );
  }
}