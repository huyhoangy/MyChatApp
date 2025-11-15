class Message {
  final String id;
  final String text;
  final String senderId;
  final DateTime timestamp;
  final bool isRecalled;

  Message({required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    this.isRecalled = false
  });

}