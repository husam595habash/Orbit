from models.notification import Notification
from repositories.base import BaseRepository


class NotificationRepository(BaseRepository[Notification]):
    model = Notification

    async def find_page_for_recipient(self, recipient_id: str, skip: int, limit: int) -> tuple[list[Notification], int]:
        query = {"recipient_id": recipient_id}
        total = await self.count(query)
        notifications = await self.find_page(query, skip=skip, limit=limit, sort=-Notification.id)
        return notifications, total

    async def mark_all_read_for_recipient(self, recipient_id: str) -> None:
        await Notification.find({"recipient_id": recipient_id}).update({"$set": {"isRead": True}})
