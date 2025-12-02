import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _showStatus = true;
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  Future<void> _loadSettings() async{
    final user =_auth.currentUser;
    if(user!=null){
      var doc =await _firestore.collection('users').doc(user.uid).get();
      if(doc.exists&&mounted){
        setState(() {
          _showStatus = doc.data()?['showStatus'] ?? true;
        });
      }
    }
  }
  Future<void> _toggleStatus(bool value)async{
    setState(() {
      _showStatus = value;
    });
    final user =_auth.currentUser;
    if(user!=null){
      await _firestore.collection('users').doc(user.uid).update({
        'showStatus':value,
        'isOnline':value,
      });
    }
  }

  void _logout(BuildContext context) async {
    try {
      final user = _auth.currentUser;
      if(user!=null){
        await _firestore.collection('users').doc(user.uid).update({'isOnline': false});
      }
      await _auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) => false, // Xoá hết
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng xuất: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(

              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _showStatus
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child:Icon(
                  Icons.circle,
                  color: _showStatus ? Colors.green : Colors.grey,
                  size: 12,
                ) ,
              ),

              minLeadingWidth: 0,

              title: const Text(
                'Trạng thái hoạt động',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text('Hiển thị khi bạn hoạt động'),
              ),
              trailing: Switch(
                value: _showStatus,
                activeColor: Colors.teal,
                onChanged: _toggleStatus,
              ),
            ),
            const Divider(),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>_logout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  )
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}