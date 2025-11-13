import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class FindFriendScreen extends StatefulWidget {
  const FindFriendScreen({Key? key}) : super(key: key);

  @override
  _FindFriendScreenState createState() => _FindFriendScreenState();
}

class _FindFriendScreenState extends State<FindFriendScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  Map<String, dynamic>? _foundUser;
  String _searchMessage = '';

  bool _isAlreadyFriend = false;
  bool _isRequestSent = false; // Đã gửi lời mời
  bool _hasPendingRequest = false; // Họ đã gửi cho mình

  Future<void> _searchFriend() async {
    final String phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) return;

    setState(() {
      _isLoading = true;
      _foundUser = null;
      _searchMessage = '';
      _isAlreadyFriend = false;
      _isRequestSent = false;
      _hasPendingRequest = false;
    });

    try {
      final String currentUserUid = _auth.currentUser!.uid;

      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo:  phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _searchMessage = 'Không tìm thấy người dùng với SĐT này.';
        });
      } else {
        _foundUser = querySnapshot.docs.first.data() as Map<String, dynamic>;
        final String foundUserUid = _foundUser!['uid'];

        if (foundUserUid == currentUserUid) {
          _foundUser = null;
          _searchMessage = 'Bạn không thể thêm chính mình.';
        } else {


          //  Kiểm tra đã là bạn bè?
          DocumentSnapshot currentUserDoc =
          await _firestore.collection('users').doc(currentUserUid).get();
          List<dynamic> friends = (currentUserDoc.data() as Map<String, dynamic>)
              .containsKey('friends')
              ? currentUserDoc.get('friends')
              : [];
          _isAlreadyFriend = friends.contains(foundUserUid);

          if (!_isAlreadyFriend) {
            //  Kiểm tra mình đã gửi lời mời cho họ?
            QuerySnapshot sentRequest = await _firestore.collection('friend_requests')
                .where('senderUid', isEqualTo:  currentUserUid)
                .where('receiverUid', isEqualTo:  foundUserUid)
                .where('status', isEqualTo:  'pending')
                .get();
            _isRequestSent = sentRequest.docs.isNotEmpty;

            if (!_isRequestSent) {
              //  Kiểm tra họ đã gửi lời mời cho mình?
              QuerySnapshot receivedRequest = await _firestore.collection('friend_requests')
                  .where('senderUid', isEqualTo:  foundUserUid)
                  .where('receiverUid', isEqualTo:  currentUserUid)
                  .where('status', isEqualTo:  'pending')
                  .get();
              _hasPendingRequest = receivedRequest.docs.isNotEmpty;
            }
          }
        }
      }
    } catch (e) {
      _searchMessage = 'Đã xảy ra lỗi khi tìm kiếm.';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendFriendRequest() async {
    if (_foundUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final String currentUserUid = _auth.currentUser!.uid;
      final String friendUserUid = _foundUser!['uid'];

      // Tạo một document mới trong 'friend_requests'
      await _firestore.collection('friend_requests').add({
        'senderUid': currentUserUid,
        'receiverUid': friendUserUid,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isRequestSent = true;
        _searchMessage = 'Đã gửi lời mời kết bạn!';
      });

    } catch (e) {
      setState(() {
        _searchMessage = 'Lỗi khi gửi lời mời.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRequest() async {
    if (_foundUser == null) return;

    setState(() { _isLoading = true; });
    try {
      final String currentUserUid = _auth.currentUser!.uid;
      final String friendUserUid = _foundUser!['uid'];

      // Tìm lời mời
      QuerySnapshot request = await _firestore.collection('friend_requests')
          .where('senderUid', isEqualTo:  friendUserUid)
          .where('receiverUid', isEqualTo:  currentUserUid)
          .where('status', isEqualTo:  'pending')
          .get();

      if (request.docs.isNotEmpty) {
        await _firestore.collection('friend_requests').doc(request.docs.first.id).update({
          'status': 'accepted'
        });

        await _firestore.collection('users').doc(currentUserUid).update({
          'friends': FieldValue.arrayUnion([friendUserUid])
        });
        await _firestore.collection('users').doc(friendUserUid).update({
          'friends': FieldValue.arrayUnion([currentUserUid])
        });

        setState(() {
          _isAlreadyFriend = true;
          _searchMessage = 'Đã chấp nhận lời mời!';
        });
      }
    } catch (e) {
      setState(() { _searchMessage = 'Lỗi khi chấp nhận.'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm bạn bè'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Nhập SĐT bạn bè',
                      prefixIcon: Icon(Icons.phone_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.search_rounded, color: Colors.teal, size: 30),
                  onPressed: _searchFriend,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.teal),
            if (_searchMessage.isNotEmpty && _foundUser == null)
              Text(_searchMessage, style: const TextStyle(color: Colors.red, fontSize: 16)),

            if (_foundUser != null)
              ListTile(
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.teal[100],
                  child: Text(
                    _foundUser!['displayName']?[0] ?? '?',
                    style: TextStyle(color: Colors.teal[800], fontSize: 24),
                  ),
                ),
                title: Text(
                  _foundUser!['displayName'] ?? 'Người dùng',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(_foundUser!['email'] ?? 'Không có email'),

                trailing: _isAlreadyFriend
                    ? const Chip(label: Text('Bạn bè'), backgroundColor: Colors.green)
                    : _isRequestSent
                    ? const Chip(label: Text('Đã gửi'), backgroundColor: Colors.grey)
                    : _hasPendingRequest
                    ? ElevatedButton(
                  onPressed: _acceptRequest,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Chấp nhận', style: TextStyle(color: Colors.white)),
                )
                    : ElevatedButton(
                  onPressed: _sendFriendRequest,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('Kết bạn', style: TextStyle(color: Colors.white)),
                ),
              ),

            if (_searchMessage.isNotEmpty && _foundUser != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _searchMessage,
                  style: TextStyle(color: _isAlreadyFriend ? Colors.green : Colors.grey, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}