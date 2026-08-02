import asyncio
import logging
import os
import sys

_BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(os.path.join(_BACKEND_DIR, "api"))

from contextlib import asynccontextmanager

from fastapi import FastAPI, WebSocket

from auth.auth_handler import decodeJWT
from connections import ws_connections
from grpc_server.notification_service import NotificationService


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        not_server = NotificationService()
        asyncio.create_task(not_server.start())
    except Exception as e:
        logging.error(f"Error starting gRPC server: {e}")
    yield

app = FastAPI(lifespan=lifespan)

# websocket endpoint
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    token = websocket.query_params.get("token")
    payload = decodeJWT(token) if token else {}
    if not payload or "user_id" not in payload:
        # Reject before accept() — never a live connection for an unverified caller.
        await websocket.close(code=4401)
        return
    user_id = payload["user_id"]

    await websocket.accept()
    logging.info(f"User {user_id} connected")

    if user_id in ws_connections:
        try:
            await ws_connections[user_id].close()
        except Exception:
            pass

    ws_connections[user_id] = websocket

    try:
      # This socket is push-only (notifications arrive via gRPC in
      # SendNotification), so nothing meaningful is expected from the
      # client here — just echo it back to keep the connection alive.
      while True:
          data = await websocket.receive_text()
          logging.info(f"Received data from user {user_id}: {data}")

          await websocket.send_text(data)
    except Exception as e:
        logging.error(f"Error: {e}")
    finally:
        del ws_connections[user_id]
        logging.info(f"User {user_id} disconnected")


# Run FastAPI Server
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8088)
