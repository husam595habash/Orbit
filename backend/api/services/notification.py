import logging
import math
import os
import sys
from typing import Optional

_REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.append(_REPO_ROOT)

from backend.realtime_notification.grpc_client import notifications as notifications_grpc_client
from models.notification import Notification, NotificationActor
from repositories.notification_repository import NotificationRepository

logger = logging.getLogger(__name__)


class NotificationService:

    def __init__(self, notification_repository: NotificationRepository):
        self.notification_repository = notification_repository

    async def get_user_notifications(self, user_id: str, page_str: Optional[str] = None):
        page = int(page_str) if page_str and page_str.isdigit() else 1
        limit = 10
        skip = (page - 1) * limit

        notifications, total = await self.notification_repository.find_page_for_recipient(user_id, skip=skip, limit=limit)

        return {
            "notifications": [n.model_dump(mode="json") for n in notifications],
            "currentPage": page,
            "numberOfPages": math.ceil(total / limit) if total else 0
        }


    async def mark_notifications_as_read(self, user_id: str, page_str: Optional[str] = None):
        await self.notification_repository.mark_all_read_for_recipient(user_id)
        return await self.get_user_notifications(user_id, page_str)


    async def create_notification(self, details: str, recipient_id: str, actor_id: str, actor_name: str, actor_image_url: str = None, isRead: bool = False):
        notification = Notification(
            details=details,
            recipient_id=recipient_id,
            actor_id=actor_id,
            isRead=isRead,
            actor=NotificationActor(
                name=actor_name,
                imageUrl=actor_image_url
            )
        )

        await self.notification_repository.save(notification)

        try:
            await notifications_grpc_client.send_notification(
                notification_id=str(notification.id),
                details=details,
                recipient_id=recipient_id,
                actor_id=actor_id,
                is_read=isRead,
                created_at=notification.createdAt,
                actor_name=actor_name,
                actor_avatar=actor_image_url,
            )
        except Exception as grpc_err:
            # A down realtime service should never block notification
            # creation — the row is already saved; the live push is best-effort.
            logger.error(f"Failed to push realtime notification: {grpc_err}")

        return {"notification_id": str(notification.id)}
