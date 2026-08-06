import '../../../../core/utils/object_id.dart';
import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.content,
    required super.sentAt,
  });

  /// From the REST history endpoint — has a real `id` to derive time from.
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return MessageModel(
      id: id,
      senderId: json['sender'] as String,
      receiverId: json['receiver'] as String,
      content: json['content'] as String,
      sentAt: dateTimeFromObjectId(id),
    );
  }

  /// From a live WebSocket push — the backend sends just
  /// `{sender, receiver, content}`, no id or timestamp.
  factory MessageModel.fromSocketJson(Map<String, dynamic> json) {
    return MessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      senderId: json['sender'] as String,
      receiverId: json['receiver'] as String,
      content: json['content'] as String,
      sentAt: DateTime.now(),
    );
  }
}
