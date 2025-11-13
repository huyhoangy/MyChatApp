import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Thêm Firestore
import '../../auth/screens/login_screen.dart';
import 'package:flutter/services.dart'; // Thêm để lọc SĐT
import '../../friend/screens/friend_list_screen.dart';
import '../../friend/screens/friend_requests_screen.dart';
import '../../friend/screens/find_friend_screen.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key ? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String _userEmail='';
  int _friendCount =0;
  int _friendRequestCount =0;

  @override
  void initState(){
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
    .listen((snapshots){
      if(mounted){
        setState(() {
          _friendRequestCount = snapshots.docs.length;
        });
      }
    });

  }
  Future<void > _loadUserData() async {
    if(!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final User?  currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists && mounted) {
          // lay du lieu ban be
          List<dynamic> friends = (userDoc.data() as Map<String,dynamic>)
          .containsKey('friends') ? userDoc.get('friends'):[];
          setState(() {
            _displayNameController.text = userDoc.get('displayName') ?? '';
            _userEmail = userDoc.get('email') ?? '';
            _phoneController.text = userDoc.get('phoneNumber') ?? '';
            _friendCount =friends.length;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải thông tin: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _updateProfile() async{
    if(_displayNameController.text.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ten khong duoc de trong'),
          backgroundColor: Colors.red,
        ),
      );
      return ;
    }
    setState(() {
      _isLoading =true;
    });
    try{
      final User? currentUser = _auth.currentUser;
      if(currentUser != null){
        await _firestore.collection('users').doc(currentUser.uid).update({
          'displayName': _displayNameController.text.trim(),
          'phoneNumber' : _phoneController.text.trim(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text (' Cap nhat thanh cong'),
            backgroundColor: Colors.green,
          )
        );
      }
    } catch (e) {
      // Xử lý lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  // xu ly dang xuat
  void _logout(BuildContext context) async{
    try{
      await FirebaseAuth.instance.signOut();
      if(context.mounted){
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) =>const LoginScreen()),
            (Route<dynamic> route) => false,
        );
      }
    } catch(e){
      if(context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi đăng xuất: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
        );
      }
    }
  }
  void _goToFindFriend(){
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const FindFriendScreen(),
    ));
  }
  void _goToFriendList(){
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const FriendListScreen(),
    ));
  }
  void _goToFriendRequests(){
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const FriendRequestsScreen(),
    ));
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body : _isLoading ? const Center(
        child: CircularProgressIndicator(color: Colors.teal)
      ): Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // khu vuc ban be
            Text(
              'Ban be',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal[800]),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.person_add_alt_1_rounded,color: Colors.orange[700],
              ),
              title: const Text('Yeu cau ket ban'),
              trailing: _friendRequestCount>0
                  ? Badge(
                label: Text('$_friendRequestCount'),
                child: const Icon (Icons.arrow_forward_ios_rounded,size: 16),
              ): const Icon(Icons.arrow_forward_ios_rounded,size: 16),
              onTap: _goToFriendRequests,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.teal[300]!),
              ),
            ),
            const SizedBox(height: 10),
            // nut tim ban
            ListTile(
              leading:Icon(Icons.person_add_rounded,color: Colors.teal,),
              title:  const Text (' Tim ban moi'),
              subtitle: const Text (' Tim bang so dien thoai '),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,size:16),
              onTap: _goToFindFriend,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.teal[300]!),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.people_rounded,color: Colors.blueGrey),
              title: const Text('Ban be cua  toi'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$_friendCount',style: const TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_ios_rounded,size:16),
                ],
              ),
              onTap: _goToFriendList,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.teal[300]!),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // phan ho so
            Text(' Ho so cua ban',
            style: TextStyle(fontSize:18 , fontWeight: FontWeight.bold,color: Colors.teal[800]) ,
            ),
            const SizedBox( height:16),
            // hien thi email
            TextField(
              controller: TextEditingController(text:_userEmail),
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_rounded),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // nhap ten
            TextField(
              controller: _displayNameController,
              decoration:InputDecoration(
                labelText: 'Ho va Ten',
                prefixIcon: Icon(Icons.person_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.teal,width: 2),
                ),
              ),
            ),
            // nhap so dien thoai
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'So dien thoai',
                prefixIcon: Icon(Icons.phone_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.teal,width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // nut cap nhat
            ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),

                ),
              ),
              child: _isLoading ? const SizedBox(height: 20,width: 20,
                child: CircularProgressIndicator(color:Colors.white,strokeWidth:3 ,))
                  :const Text('Cap nhat ho so',
                  style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold))
            ),
            // dang xuat
            const SizedBox(height: 30),
            const Divider(), // duong ke phan cach
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: ()=>_logout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Dang xuat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  padding : const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  )
                ),
              ),
            )
          ],
        )
      )
    );

  }

}
