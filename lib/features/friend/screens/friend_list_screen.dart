import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../chat/screens/chat_screen.dart';

class FriendListScreen extends StatefulWidget{
  const FriendListScreen({Key? key}) : super(key: key);
  @override
  _FriendListScreenState createState() => _FriendListScreenState();
}
class _FriendListScreenState extends State<FriendListScreen>{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // ham huy ket ban
  Future<void> _unfriend(String friendUid) async{
    final String currentUserUid = _auth.currentUser!.uid;
    bool confirm = await showDialog(
      context: context,
      builder:(BuildContext context){
        return AlertDialog(
          title: const Text('Xác nhận'),
          content: const Text('Bạn có chắc chắn muốn hủy kết bạn?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Khong'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Co',style: TextStyle(color: Colors.red)),
            ),
          ],

        );
      },
    );
    if(confirm!= true) return;
    try{
      await _firestore.collection('users').doc(currentUserUid).update({
        'friends' :FieldValue.arrayRemove([friendUid]),
      });
      await _firestore.collection('users').doc(friendUid).update({
        'friends' :FieldValue.arrayRemove([currentUserUid]),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Da huy ket ban'),
          backgroundColor: Colors.green,
        ),
      );
    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('loi huy ket ban: ${e.toString()}'),
        )
      );
    }
  }
  @override
  Widget build (BuildContext context){
    final String currentUserUid = _auth.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ban be'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(currentUserUid).snapshots(),
        builder: (context,snapshot){
          if(snapshot.connectionState==ConnectionState.waiting){
            return const Center(child: CircularProgressIndicator());
          }
          if(!snapshot.hasData || !snapshot.data!.exists){
            return const Center(child: Text(' Khong tim thay nguoi dung'));
          }
          List <dynamic> friendUids =(snapshot.data!.data()as Map<String,dynamic>)
          .containsKey('friends')? snapshot.data!.get('friends') : [];
          if(friendUids.isEmpty){
            return const Center(child: Text('Khong co ban be'));
          }
          return ListView.builder(
            itemCount: friendUids.length,
            itemBuilder: (context,index){
              String friendUid = friendUids[index];
              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(friendUid).get(),
                builder: (context,friendSnapshot){
                  if(!friendSnapshot.hasData){
                    return const ListTile(title: Text('Dang tai'));
                  }
                  var friendData = friendSnapshot.data!.data() as Map<String,dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.teal[100],
                      child: Text(
                        friendData['displayName']?[0]??'?',
                        style: TextStyle(color: Colors.teal[800]),
                      ),
                    ),
                    title: Text(friendData['displayName'] ?? ' Nguoi dung'),
                    subtitle: Text(friendData['phoneNumber'] ??'Chua co SDT'),
                    onTap: (){
                      Navigator.push(context,MaterialPageRoute(
                        builder: (context)=> ChatScreen(
                          receiverUid: friendUid,
                          receiverName: friendData['displayName'] ?? 'Nguoi dung',
                        ),
                      ));
                    },
                    trailing: IconButton(
                      icon: Icon(Icons.person_remove,color: Colors.red[400]),
                      onPressed: () => _unfriend(friendUid),
                    ),
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