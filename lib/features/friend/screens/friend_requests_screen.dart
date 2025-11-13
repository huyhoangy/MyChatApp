import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class FriendRequestsScreen extends StatefulWidget{
  const FriendRequestsScreen({Key? key}) : super(key: key);
  @override
  _FriendRequestsScreenState createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen>{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // ham chap nhan loi moi
  Future<void> _accepetRequest(String requestId, String senderUid) async{
    final String currentUserUid = _auth.currentUser!.uid;
    try{
      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': 'accepted',
      });
      await _firestore.collection('users').doc(currentUserUid).update({
        'friends': FieldValue.arrayUnion([senderUid])
      });
      await _firestore.collection('users').doc(senderUid).update({
        'friends': FieldValue.arrayUnion([currentUserUid])
      });
    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('loi chap nhan loi moi: ${e.toString()}'),
        )
      );
    }
  }
  // ham tu choi
  Future<void> _declineRequest(String requsetId) async{
    try{
      await _firestore.collection('friend_requests').doc(requsetId).delete();
    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('loi tu choi loi moi: ${e.toString()}'),
      ));
    }
  }
  @override
  Widget build(BuildContext context){
    final String currentUserUid = _auth.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeu cau ket ban'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('friend_requests')
            .where('receiverUid', isEqualTo:  currentUserUid)
            .where('status', isEqualTo:  'pending')
            .snapshots(),
        builder: (context, snapshot){
          if(snapshot.connectionState==ConnectionState.waiting){
            return const Center(child: CircularProgressIndicator());
          }
          if(!snapshot.hasData || snapshot.data!.docs.isEmpty){
            return const Center(child: Text('Khong co loi moi'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context,index){
              var request = snapshot.data!.docs[index];
              var requestData = request.data() as Map<String,dynamic>;
              String senderUid = requestData['senderUid'];
              String requestId = request.id;
              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(senderUid).get(),
                builder: (context,senderSnapshot){
                  if(!senderSnapshot.hasData){
                    return const ListTile(title: Text('Dang tai'));
                  }
                  var senderData = senderSnapshot.data!.data() as Map<String,dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 5.0,horizontal: 10.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.teal[100],
                        child: Text(senderData['displayName']?[0]??'?'),
                      ),
                      title: Text(senderData['displayName'] ??'Nguoi dung'),
                      subtitle: Text(senderData['email']??'...'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // nut tu choi
                          IconButton(
                            icon:  const Icon(Icons.close,color: Colors.red),
                            onPressed: ()=> _declineRequest(requestId),
                          ),
                          // nut dong y
                          IconButton(
                            icon: const Icon(Icons.check,color: Colors.green),
                            onPressed: ()=> _accepetRequest(requestId,senderUid),
                          ),
                        ],
                      ),
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