import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/network/backend_host.dart';

/// One WebSocket connection to the realtime_chat server — a separate
/// process from the main API (see backend/realtime_chat/app.py, port 8001)
/// — shared for as long as the user is anywhere inside the chat feature.
///
/// Deliberately minimal for a first pass: no reconnect-with-backoff, and no
/// online-presence handling (the server also broadcasts an `onlineFriends`
/// list down this same socket; this service just ignores anything that
/// isn't a chat message).
class ChatSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get incomingMessages => _controller.stream;

  Future<void> connect({required String? token}) async {
    final uri = Uri.parse('ws://$backendHost:8001/ws?token=$token');
    final channel = WebSocketChannel.connect(uri);
    await channel.ready;
    _channel = channel;
    _subscription = channel.stream.listen(_handleIncoming);
  }

  void _handleIncoming(dynamic raw) {
    if (raw is! String) return;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return;
    // Ignore anything that isn't a chat message — e.g. the server's
    // {"onlineFriends": [...]} presence broadcasts or {"type": "error"}.
    if (!decoded.containsKey('content') || !decoded.containsKey('sender')) return;
    _controller.add(decoded);
  }

  void send({required String receiverId, required String content}) {
    _channel?.sink.add(jsonEncode({'content': content, 'receiver': receiverId}));
  }

  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _controller.close();
  }
}
