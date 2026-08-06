import '../../../../core/utils/object_id.dart';
import '../../domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.partnerId,
    required super.partnerName,
    required super.partnerUsername,
    required super.partnerImageUrl,
    required super.lastMessage,
    required super.lastMessageAt,
    required super.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      partnerId: json['partnerId'] as String,
      partnerName: json['partnerName'] as String,
      partnerUsername: json['partnerUsername'] as String,
      partnerImageUrl: json['partnerImageUrl'] as String? ?? '',
      lastMessage: json['lastMessage'] as String,
      lastMessageAt: dateTimeFromObjectId(json['lastMessageId'] as String),
      unreadCount: json['unreadCount'] as int,
    );
  }
}
