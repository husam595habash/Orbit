class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String content;

  /// The backend doesn't store a timestamp on messages — this is derived
  /// from the Mongo ObjectId's embedded creation time (history), or just
  /// `DateTime.now()` for messages that arrived live over the socket.
  final DateTime sentAt;
}
