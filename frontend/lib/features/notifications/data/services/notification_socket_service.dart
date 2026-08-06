import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/network/backend_host.dart';

/// One WebSocket connection to the realtime_notification server — a
/// separate process from the main API (see
/// backend/realtime_notification/app.py, port 8088) — kept alive for as
/// long as the Notifications tab (or any screen watching it) is mounted.
///
/// This socket is push-only: the server never expects anything meaningful
/// back, it just delivers a JSON payload per notification as it happens.
class NotificationSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get incomingNotifications => _controller.stream;

  Future<void> connect({required String? token}) async {
    final uri = Uri.parse('ws://$backendHost:8088/ws?token=$token');
    final channel = WebSocketChannel.connect(uri);
    await channel.ready;
    _channel = channel;
    _subscription = channel.stream.listen(_handleIncoming);
  }

  void _handleIncoming(dynamic raw) {
    if (raw is! String) return;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return;
    if (!decoded.containsKey('details')) return;
    _controller.add(decoded);
  }

  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _controller.close();
  }
}
