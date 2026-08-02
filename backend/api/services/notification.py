import logging
import math
import os
import sys
from typing import Optional

_REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.append(_REPO_ROOT)

from backend.realtime_notification.grpc_client import notifications as notifications_grpc_client
from models.notification import Notification, NotificationActor

logger = logging.getLogger(__name__)


class NotificationService:
    @staticmethod
    async def get_user_notifications(user_id: str, page_str: Optional[str] = None):
        try:
            page = int(page_str) if page_str and page_str.isdigit() else 1
            limit = 10
            skip = (page - 1) * limit

            notification_filter = {"recipient_id": user_id}
            total = await Notification.find(notification_filter).count()
            notifications = await Notification.find(notification_filter) \
                .sort(-Notification.id).skip(skip).limit(limit).to_list()

            return {
                "notifications": [n.model_dump(mode="json") for n in notifications],
                "currentPage": page,
                "numberOfPages": math.ceil(total / limit) if total else 0
            }
        except Exception as e:
            logger.error(e)
            return None



    @staticmethod
    async def mark_notifications_as_read(user_id: str, page_str: Optional[str] = None):
        try:
            notification_filter = {"recipient_id": user_id}
            await Notification.find(notification_filter).update({"$set": {"isRead": True}})
            return await NotificationService.get_user_notifications(user_id, page_str)
        except Exception as e:
            logger.error(e)
            return None



    @staticmethod
    async def create_notification(details: str, recipient_id: str, actor_id: str, actor_name: str, actor_image_url: str = None, isRead: bool = False):
        try:
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

            await notification.save()

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
        except Exception as e:
            logger.error(e)
            return None

