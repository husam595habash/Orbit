class Conversation {
  const Conversation({
    required this.partnerId,
    required this.partnerName,
    required this.partnerUsername,
    required this.partnerImageUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  final String partnerId;
  final String partnerName;
  final String partnerUsername;
  final String partnerImageUrl;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
}
