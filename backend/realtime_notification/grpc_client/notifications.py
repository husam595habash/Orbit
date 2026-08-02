from datetime import datetime
from typing import Optional
import os
import sys

import grpc
from google.protobuf.timestamp_pb2 import Timestamp

_REALTIME_NOTIFICATION_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(os.path.join(_REALTIME_NOTIFICATION_DIR, "protos"))

from notification_pb2_grpc import NotificationServiceStub
from notification_pb2 import NotificationActor, NotificationRequest

# Plain os.environ instead of decouple.config: decouple's config object is a
# process-wide singleton that picks its .env search path from whichever
# caller invokes it first and caches that for every later call — mixing it
# in here risks poisoning auth_handler's unrelated `secret`/`algorithm` lookup
# depending on import order.
NOTIFICATION_GRPC_ADDRESS = os.environ.get("NOTIFICATION_GRPC_ADDRESS", "localhost:8090")

# One channel, reused for every call, instead of opening a new connection
# per RPC. grpc.aio channels are meant to be long-lived and handle their
# own reconnection internally.
_channel = None
_stub = None


def _get_stub() -> NotificationServiceStub:
    global _channel, _stub
    if _stub is None:
        _channel = grpc.aio.insecure_channel(NOTIFICATION_GRPC_ADDRESS)
        _stub = NotificationServiceStub(_channel)
    return _stub


async def send_notification(
    notification_id: str,
    details: str,
    recipient_id: str,
    actor_id: str,
    is_read: bool,
    created_at: datetime,
    actor_name: str,
    actor_avatar: Optional[str],
) -> None:
    stub = _get_stub()

    created_at_ts = Timestamp()
    created_at_ts.FromDatetime(created_at)

    request = NotificationRequest(
        id=notification_id,
        details=details,
        recipient_id=recipient_id,
        actor_id=actor_id,
        is_read=is_read,
        created_at=created_at_ts,
        actor=NotificationActor(name=actor_name, avatar=actor_avatar or ""),
    )
    await stub.SendNotification(request)
