from typing import Dict

from fastapi import WebSocket

# Shared between the websocket endpoint (app.py) and the gRPC servicer
# (grpc_server/notification_service.py) — both need to see the same
# live set of connected users.
ws_connections: Dict[str, WebSocket] = {}