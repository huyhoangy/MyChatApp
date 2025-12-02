import 'package:flutter/material.dart';
import 'chat_list_screen.dart';
import 'settings_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<Widget> _widgetOptions = <Widget>[
    ChatListScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];
  @override
  void initState(){
    super.initState();
    _setupFCM();
    _setUserStatus(true);
  }
  @override
  void dispose(){
    WidgetsBinding.instance.removeObserver(this);
    _setUserStatus(false);
    super.dispose();
  }
  @override
  void  didChangeAppLifecycleState(AppLifecycleState state){
    if(state== AppLifecycleState.resumed){
      _setUserStatus(true);
    }
    else {
      _setUserStatus(false);
    }
  }
  void _setUserStatus(bool isOnline) async{
    final user = _auth.currentUser;
    if(user!=null){
      var doc = await _firestore.collection('users').doc(user.uid).get();
      bool showStatus =doc.data()?['showStatus']??true;
      if(!showStatus){
        isOnline =false;
      }
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastActive': FieldValue.serverTimestamp(), // Lưu thời gian
      });
    }
  }
  void _setupFCM() async{
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound:true,
    );
    String ?token = await _firebaseMessaging.getToken();
    if(token!=null){
      print("FCM Token: $token"); // In ra để kiểm tra
      String ? currentUserUid = _auth.currentUser?.uid;
      if(currentUserUid!=null){
        await _firestore.collection('users').doc(currentUserUid).update({
          'fcmToken':token,
        });
      }
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage message){
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      if(message.notification!=null){
        print('Message also contained a notification: ${message.notification}');
        // Bạn có thể hiển thị một SnackBar hoặc Dialog tại đây
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Hồ sơ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal[800],
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
      ),
    );
  }
}