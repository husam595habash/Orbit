from datetime import datetime, timezone
from beanie import Document
from pydantic import Field

class Comment(Document):
    post_id: str
    user_id: str
    value: str
    createdAt: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    class Settings:
        name = "comments"
        indexes = [[("post_id", 1), ("_id", -1)]]
