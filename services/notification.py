import logging

from models.notification import Notification, NotificationActor

logger = logging.getLogger(__name__)


class NotificationService:
    @staticmethod
    async def get_user_notifications(user_id: str):
        try:
            notification_filter = {"recipient_id": user_id}
            notifications = await Notification.find(notification_filter).sort(-Notification.id).to_list()

            return {"notifications": [n.model_dump(mode="json") for n in notifications]}
        except Exception as e:
            logger.error(e)
            return None



    @staticmethod
    async def mark_notifications_as_read(user_id: str):
        try:
            notification_filter = {"recipient_id": user_id}
            await Notification.find(notification_filter).update({"$set": {"isRead": True}})
            notifications = await Notification.find(notification_filter).sort(-Notification.id).to_list()

            return {"notifications": [n.model_dump(mode="json") for n in notifications]}
        except Exception as e:
            logger.error(e)
            return None



    @staticmethod
    async def create_notification(details: str, recipient_id: str, actor_id: str, actor_name: str, actor_avatar: str = None, isRead: bool = False):
        try:
            notification = Notification(
                details=details,
                recipient_id=recipient_id,
                actor_id=actor_id,
                isRead=isRead,
                actor=NotificationActor(
                    name=actor_name,
                    avatar=actor_avatar
                )
            )

            # TODO calling gRPC here

            await notification.save()
            return {"notification_id": str(notification.id)}
        except Exception as e:
            logger.error(e)
            return None

