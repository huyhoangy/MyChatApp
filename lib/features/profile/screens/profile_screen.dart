import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../friend/screens/find_friend_screen.dart';
import '../../friend/screens/friend_list_screen.dart';
import '../../friend/screens/friend_requests_screen.dart';
import 'dart:io'; // Để dùng kiểu File
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = true;
  String _userEmail = '';
  int _friendCount = 0;
  int _friendRequestCount = 0;
  String _avatarUrl ='';
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _listenForFriendRequests();
  }


  void _listenForFriendRequests() {
    final String currentUserUid = _auth.currentUser!.uid;
    _firestore.collection('friend_requests')
        .where('receiverUid', isEqualTo: currentUserUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshots) {
      if (mounted) {
        setState(() {
          _friendRequestCount = snapshots.docs.length;
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists && mounted) {
          List<dynamic> friends = (userDoc.data() as Map<String, dynamic>)
              .containsKey('friends') ? userDoc.get('friends') : [];
          setState(() {
            _displayNameController.text = userDoc.get('displayName') ?? '';
            _userEmail = userDoc.get('email') ?? '';
            _phoneController.text = userDoc.get('phoneNumber') ?? '';
            _friendCount = friends.length;
            _avatarUrl =userDoc.get('photoUrl') ?? '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thông tin: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }
  Future<void> _changeAvatar() async{
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if(image == null) return;
    File imageFile = File(image.path);
    setState(() {
      _isUploading=true;
    });
    try{
      final cloudinary = CloudinaryPublic(
      'dtcxoncos','flutter_uploads_chatapp' ,
      cache: false
      );
      //  Tải ảnh lên
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, resourceType: CloudinaryResourceType.Image
        ,folder: 'avatarChatApp'),
      );
      String newImageUrl = response.secureUrl;
      final String currentUserUid = _auth.currentUser!.uid;
      await _firestore.collection('users').doc(currentUserUid).update({
        'photoUrl': newImageUrl,
      });
      setState(() {
        _avatarUrl= newImageUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!'), backgroundColor: Colors.green),
      );
    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải ảnh: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally{
      setState(() {
        _isUploading=false;
      });
    }

  }

  Future<void> _updateProfile() async {
    if (_displayNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên không được để trống'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() { _isLoading = true; });

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'displayName': _displayNameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _goToFindFriend() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const FindFriendScreen(),
    ));
  }

  void _goToFriendList() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const FriendListScreen(),
    ));
  }

  void _goToFriendRequests() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const FriendRequestsScreen(),
    ));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ '),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius:60,
                    backgroundColor: Colors.grey[200],
                    child: _isUploading
                    ?const CircularProgressIndicator(color: Colors.teal)
                    :_avatarUrl.isNotEmpty? ClipOval(
                      child: Image.network(
                        _avatarUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context,error,stackTrace)=>
                        const Icon(Icons.person,size: 60,color: Colors.grey),
                      ),
                    ): const Icon(Icons.person,size: 60,color: Colors.grey),
                  ),
                  // nut chinh sua
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white,size: 20),
                        onPressed: _isUploading? null:_changeAvatar,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              'Hồ sơ của bạn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal[800]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: _userEmail),
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_rounded),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: Icon(Icons.person_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.teal, width: 2)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: Icon(Icons.phone_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.teal, width: 2)),
              ),
            ),
            const SizedBox(height: 24),

            // Nút Cập nhật
            ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text('Cập nhật hồ sơ', style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            Text(
              'Bạn bè',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal[800]),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.person_add_alt_1_rounded, color: Colors.orange[700]),
              title: const Text('Lời mời kết bạn'),
              trailing: _friendRequestCount > 0
                  ? Badge(
                label: Text('$_friendRequestCount'),
                child: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              )
                  : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: _goToFriendRequests,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.person_add_rounded, color: Colors.teal),
              title: const Text('Tìm bạn bè mới'),
              subtitle: const Text('Tìm bằng số điện thoại'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: _goToFindFriend,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.people_rounded, color: Colors.blueGrey),
              title: const Text('Bạn bè của tôi'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_friendCount',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ],
              ),
              onTap: _goToFriendList,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}