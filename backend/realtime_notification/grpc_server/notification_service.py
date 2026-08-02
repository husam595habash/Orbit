import logging
import os
import sys

_REALTIME_NOTIFICATION_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(os.path.join(_REALTIME_NOTIFICATION_DIR, "protos"))

from concurrent import futures

import grpc
import google.protobuf.empty_pb2 as empty_pb2

from notification_pb2_grpc import NotificationServiceServicer, add_NotificationServiceServicer_to_server

from connections import ws_connections


class NotificationService(NotificationServiceServicer):
    async def start(self) -> None:
        thread_pool = futures.ThreadPoolExecutor(max_workers=10)
        server = grpc.aio.server(thread_pool)
        add_NotificationServiceServicer_to_server(self, server)
        server.add_insecure_port('[::]:8090')
        await server.start()
        logging.info("gRPC running on 8090")
        await server.wait_for_termination()

    async def SendNotification(self, request, context):
        try:
            user_id = request.recipient_id
            if user_id in ws_connections:
                websocket = ws_connections[user_id]

                created_at_str = request.created_at.ToJsonString()

                data = {
                    "id": request.id,
                    "details": request.details,
                    "recipient_id": request.recipient_id,
                    "actor_id": request.actor_id,
                    
                    "is_read": request.is_read,
                    "createdAt": created_at_str,
                    "user": {
                        "name": request.actor.name,
                        "avatar": request.actor.avatar
                    }
                }

                # send ws message
                await websocket.send_json(data)
                logging.info(f"sent WebSocket message to user {user_id}")
            else:
                logging.info(f"User {user_id} not connected")
            return empty_pb2.Empty()

        except Exception as e:
            logging.error(f"Error processing gRPC Notification: {e}")
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details('Failed to process notification')
            return empty_pb2.Empty()