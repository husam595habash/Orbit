from datetime import datetime
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
    comments: Optional[List[str]] = Field(default=[])
    createdAt: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        collection = "posts"
        indexes = [[("title", pymongo.TEXT), ("message", pymongo.TEXT)]]