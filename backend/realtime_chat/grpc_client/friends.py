from typing import List
import os
import sys
import grpc

_REALTIME_CHAT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(os.path.join(_REALTIME_CHAT_DIR, "protos"))

from chat_pb2_grpc import RealTimeChatServiceStub
from chat_pb2 import UserID, MessageRequest

# Plain os.environ instead of decouple.config: decouple's config object is a
# process-wide singleton that picks its .env search path from whichever
# caller invokes it first and caches that for every later call — mixing it
# in here risks poisoning auth_handler's unrelated `secret`/`algorithm` lookup
# depending on import order.
CHAT_GRPC_ADDRESS = os.environ.get("CHAT_GRPC_ADDRESS", "localhost:5001")

# One channel, reused for every call, instead of opening a new connection
# per RPC. grpc.aio channels are meant to be long-lived and handle their
# own reconnection internally.
_channel = None
_stub = None


def _get_stub() -> RealTimeChatServiceStub:
    global _channel, _stub
    if _stub is None:
        _channel = grpc.aio.insecure_channel(CHAT_GRPC_ADDRESS)
        _stub = RealTimeChatServiceStub(_channel)
    return _stub


async def get_user_friends(user_id: str) -> List[str]:
    stub = _get_stub()
    user_id_message = UserID(user_id=user_id)
    response = await stub.GetUserFollowingFollowers(user_id_message)

    return response.following

async def send_message(msg):
    stub = _get_stub()
    message = MessageRequest(sender=msg['sender'], receiver=msg['receiver'], content=msg['content'])
    response = await stub.SendMessage(message)
    return response.message