from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime, timezone
from beanie import Document


class NotificationActor(BaseModel):
    name: str
    imageUrl: Optional[str] = None

class Notification(Document):
    details: str
    recipient_id: str
    actor_id: str
    isRead: bool = False
    createdAt: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    actor: NotificationActor
    class Settings:
        collection = "notifications"
