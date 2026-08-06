import 'message.dart';

class MessagePage {
  const MessagePage({
    required this.messages,
    required this.currentPage,
    required this.numberOfPages,
  });

  final List<Message> messages;
  final int currentPage;
  final int numberOfPages;

  bool get hasMore => currentPage < numberOfPages - 1;
}
