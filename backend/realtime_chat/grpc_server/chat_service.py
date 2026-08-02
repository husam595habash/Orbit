import os
import sys

import grpc

_REALTIME_CHAT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(os.path.join(_REALTIME_CHAT_DIR, "protos"))

from chat_pb2 import MessageResponse, UserIDsListResponses
from chat_pb2_grpc import RealTimeChatServiceServicer, add_RealTimeChatServiceServicer_to_server
from schemas.message import CreateMessage
from services.chat import ChatService
from services.user import UserService


class ChatServer(RealTimeChatServiceServicer):
    def __init__(self):
        self.server = None
   
    async def start(self) -> None:
        self.server = grpc.aio.server()
        add_RealTimeChatServiceServicer_to_server(self, self.server)
        self.server.add_insecure_port('[::]:5001')

        await self.server.start()
        await self.server.wait_for_termination()




    async def SendMessage(self, request, context):
        msg = CreateMessage(content=request.content, receiver=request.receiver)
        result = await ChatService.send_message(msg, request.sender)
        if not result:
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details('Failed to send message')
            return MessageResponse()

        return MessageResponse(message="sent")
    



    async def stop(self):
        if self.server:
            await self.server.stop(0)
    


    async def GetUserFollowingFollowers(self, request, context):
        user = await UserService.get_user_by_id(request.user_id)
        if not user:
            context.set_code(grpc.StatusCode.NOT_FOUND)
            context.set_details('User not found')
            return UserIDsListResponses()

        return UserIDsListResponses(followers=user.followers, following=user.following)
