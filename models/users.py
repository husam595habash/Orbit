from typing import List, Optional
from beanie import Document, Indexed
from pydantic import Field, EmailStr
import pymongo



class User(Document):
    name: str
    lastname: str
    email: Indexed(EmailStr, unique=True)
    password: str
    bio: Optional[str] = Field(default="")
    imageUrl: Optional[str] = Field(default="")
    followers: Optional[List[str]] = Field(default=[])
    following: Optional[List[str]] = Field(default=[])


    class Settings:
        collection = "users"
        indexes = [[("name", pymongo.TEXT), ("email", pymongo.TEXT)]]