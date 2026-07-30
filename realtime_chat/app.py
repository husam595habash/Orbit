
from fastapi import FastAPI , WebSocket, WebSocketDisconnect

import logging
import os
import sys

sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "api"))

from grpc_client import firends
from auth.auth_handler import decodeJWT
from interface.message import CreateMessage


class ConnectionManager:
    def __init__(self):
        self.connections: dict = {}

    # Fetch user_id's friends, work out which are currently online, and send
    # that list to the given websocket. Returns the online list so callers
    # that already need it (e.g. to loop over) don't have to re-fetch it.
    async def notify_online_friends(self, user_id: str, websocket: WebSocket) -> list:
        friends_list = set(await firends.get_user_friends(user_id))
        online = [fid for fid in friends_list if fid in self.connections]
        try:
            await websocket.send_json({"onlineFriends": online})
        except Exception as e:
            logging.error(f"Error sending online-friends list to {user_id}: {e}")
        return online

    async def add_connection(self, user_id: str, websocket: WebSocket):
        await websocket.accept()

        if user_id in self.connections:
            try:
                await self.connections[user_id].close()

            except Exception:
                pass

        self.connections[user_id] = websocket
        logging.info(f"User {user_id} connected. Online users: {list(self.connections.keys())}")

        # Tell this user who their online friends are, then tell each of
        # those online friends that this user just came online too.
        my_online_friends = await self.notify_online_friends(user_id, websocket)
        for friend_id in my_online_friends:
            friend_ws = self.connections.get(friend_id)
            if friend_ws:
                await self.notify_online_friends(friend_id, friend_ws)

                

    # remove connection
    async def remove_connection(self, user_id: str):
        if user_id not in self.connections:
            logging.warning(f"User {user_id} not in connections on removal.")
            return
        del self.connections[user_id]
        logging.info(f"User {user_id} disconnected ")
        my_friends = set(await firends.get_user_friends(user_id))
        for friend_id in my_friends:
            friend_ws = self.connections.get(friend_id)
            if friend_ws:
                await self.notify_online_friends(friend_id, friend_ws)
    # send to receiver
    async def send_to_receiver(self, sender_id: str, msg: CreateMessage):
        receiver = msg.receiver
        receiver_ws = self.connections.get(receiver)
        sender_ws = self.connections.get(sender_id)
        outgoing = {"sender": sender_id, "receiver": msg.receiver, "content": msg.content}

        try:
            await firends.send_message(outgoing)
        except Exception as e:
            logging.error(f"Error saving message to db via gRPC: {e}")
            if sender_ws:
                try:
                    await sender_ws.send_json({"type": "error", "message": "Failed to save message"})
                except Exception as notify_err:
                    logging.error(f"Error notifying {sender_id} of save failure: {notify_err}")


        if receiver_ws:
            try:
                await receiver_ws.send_json(outgoing)
            except Exception as e:
                logging.error(f"Error sending realtime message to {receiver}: {e}")

app = FastAPI()
manager = ConnectionManager()

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    token = websocket.query_params.get("token")
    payload = decodeJWT(token) if token else {}
    if not payload or "user_id" not in payload:
        # Reject before accept() — never a live connection for an unverified caller.
        await websocket.close(code=4401)
        return
    id = payload["user_id"]

    await manager.add_connection(id, websocket)
    try:
        while True:
            data = await websocket.receive_json()

            if data.get("type") == 'requestOnline':
                await manager.notify_online_friends(id, websocket)
                continue
            try:
                msg = CreateMessage(**data)
            except Exception as e:
                logging.error(f"Invalid message from {id}: {e}")
                try:
                    await websocket.send_json({"type": "error", "message": "Invalid message format"})
                except Exception as notify_err:
                    logging.error(f"Error notifying {id} of invalid message: {notify_err}")
                continue
            await manager.send_to_receiver(id, msg)
    except WebSocketDisconnect:
        logging.info(f"WebSocket disconnected for user {id}")
    except Exception as e:
        logging.error(f"WebSocket Error for user {id}: {e}")
    finally:
        await manager.remove_connection(id)
    
    

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)