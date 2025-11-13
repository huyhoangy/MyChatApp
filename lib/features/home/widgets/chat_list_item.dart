import 'package:flutter/material.dart';
import '../../chat/screens/chat_screen.dart';
class ChatListItem extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final String imageUrl;
  const ChatListItem({
    Key ? key,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.imageUrl,
  }):super(key:key);
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0,horizontal: 16.0),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(imageUrl),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        time,
        style: const TextStyle(fontSize: 12.0, color: Colors.grey),
      ),
      onTap: (){
        // Tạm thời, mọi cuộc chat đều dẫn đến màn hình ChatScreen mock
        // Sau này, chúng ta sẽ truyền ID phòng chat vào đây
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ChatScreen(receiverUid: 'mock_uid_${name}',
            receiverName: name,),
        ));
      },
    );
  }
}