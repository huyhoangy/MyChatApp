import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String text;
  final String senderId;
  final String receiverId;
  final DateTime timestamp;
  final bool isRecalled;
  final String? imageUrl;

  Message({
    required this.id,
    required this.text,
    required this.senderId,
    this.receiverId = '',
    required this.timestamp,
    this.isRecalled = false,
    this.imageUrl,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      text: data['text'] ?? '',
      senderId: data['senderUid'] ?? '',
      receiverId: data['receiverUid'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRecalled: data['isRecalled'] ?? false,
      imageUrl: data['imageUrl'],
    );
  }
}