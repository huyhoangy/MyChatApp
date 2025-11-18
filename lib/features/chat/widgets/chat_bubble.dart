import 'package:flutter/material.dart';
import '../../../core/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class ChatBubble extends StatelessWidget{
  final Message message;
  final bool isMe;
  final String ? nickname;
  const ChatBubble({Key? key,
    required this.message, required this.isMe,this.nickname}): super(key: key);

  @override
  Widget build(BuildContext context) {
    if(message.senderId == 'system'){
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              fontSize: 12.0,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        )
      );
    }
    if(isMe){
      return Align(
        alignment: Alignment.centerRight,
        child:_buildMessageContainer(isMe:true),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0,horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(message.senderId).get(),
            builder: (context,snapshot){
              Widget defaultAvatar=CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                child:const Icon(Icons.person,color:Colors.white,size:16 ),
              );
              if(!snapshot.hasData||!snapshot.data!.exists){
                return defaultAvatar;
              }
              var userData = snapshot.data!.data() as Map<String,dynamic>;
              String? photoUrl = userData['photoUrl'];
              String displayName =nickname ?? userData['displayName']??'?';
              if(photoUrl!=null && photoUrl.isNotEmpty){
                return CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(photoUrl),
                );
              } else{
                return CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.teal[100],
                  child:Text(
                    displayName.isNotEmpty?displayName[0].toUpperCase():'?',
                    style: TextStyle(fontSize: 12,color: Colors.teal[800],fontWeight: FontWeight.bold),
                  ),
                );
              }
            },
          ),
          const SizedBox(width:8.0),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(message.senderId).get(),
                  builder:(context,snapshot){
                    String displayName='...';
                    if(nickname!=null){
                      displayName=nickname!;
                    } else if(snapshot.hasData && snapshot.data!.exists){
                      var data = snapshot.data!.data() as Map<String,dynamic>;
                      displayName=data['displayName']??'Người lạ';
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2.0,left: 4.0),
                      child: Text(
                        displayName,
                        style: const TextStyle(fontSize: 11,color: Colors.grey,fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
                _buildMessageContainer(isMe: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMessageContainer({required bool isMe}){
    return Container(
      margin: isMe
      ? const EdgeInsets.symmetric(vertical: 4.0,horizontal: 8.0)
          : EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14.0,vertical: 10.0),
      decoration: BoxDecoration(
        color: isMe ? Colors.teal[300] : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18.0),
          topRight: const Radius.circular(18.0),
          bottomLeft: isMe ? const Radius.circular(18.0) : const Radius.circular(0),
          bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(18.0),
        ) ,
        boxShadow:[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
              message.isRecalled ?'Tin nhắn đã được thu hồi':message.text,
            style: TextStyle(
              fontSize: 16.0,
              color:Colors.black87,
              fontStyle: message.isRecalled ? FontStyle.italic : FontStyle.normal,
              decoration: message.isRecalled ? TextDecoration.lineThrough : null,
              decorationColor: Colors.black54,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 10.0,
              color:Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}