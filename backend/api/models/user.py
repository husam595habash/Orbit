from typing import List, Optional
from beanie import Document, Indexed
from pydantic import Field, EmailStr


class User(Document):
    firstname: str
    lastname: str
    username: Indexed(str, unique=True)
    email: Indexed(EmailStr, unique=True)
    password: Optional[str] = None
    bio: Optional[str] = Field(default="")
    imageUrl: Optional[str] = Field(default="")
    followers: Optional[List[str]] = Field(default=[])
    following: Optional[List[str]] = Field(default=[])


    class Settings:
        name = "users"