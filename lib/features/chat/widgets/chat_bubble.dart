import 'package:flutter/material.dart';
import '../../../core/models/message_model.dart';

class ChatBubble extends StatelessWidget{
  final Message message;
  final bool isMe;
  const ChatBubble({Key? key,
    required this.message, required this.isMe}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0,horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 14.0),
        decoration: BoxDecoration(
          color: isMe ? Colors.teal[300] : Colors.white, // mau bong bong
          borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18.0),
          topRight: const Radius.circular(18.0),
          bottomLeft: isMe ? const Radius.circular(18.0) : const Radius.circular(0.0),
          bottomRight: isMe ? const Radius.circular(0.0) : const Radius.circular(18.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(message.text,
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.black87,
                ),
              ),
                const SizedBox(height: 4.0),
                Text(
                    // Định dạng thời gian đơn giản
                    '${message.timestamp.hour}:'
                        '${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 11.0,
                      color: Colors.black54,
                    ),
                ),
            ],
          ),
      )
    );
  }
}