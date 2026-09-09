from datetime import datetime, timezone
from typing import List, Optional
from beanie import Document
from pydantic import Field
import pymongo


class Post(Document):
    title: str
    message: str
    creator: str
    selectedFile: Optional[str] = Field(default="")
    likes: Optional[List[str]] = Field(default=[])
    createdAt: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    class Settings:
        name = "posts"
        indexes = [
            [("title", pymongo.TEXT), ("message", pymongo.TEXT)],
            [("creator", 1), ("createdAt", -1)],
        ]