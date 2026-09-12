import re
from typing import Optional

from models.user import User
from repositories.base import BaseRepository


class UserRepository(BaseRepository[User]):
    model = User

    async def find_by_email(self, email: str) -> Optional[User]:
        return await User.find_one(User.email == email)

    async def search(self, words: list[str], skip: int, limit: int) -> tuple[list[User], int]:
        query = {"$and": [
            {"$or": [
                {"firstname": {"$regex": re.escape(word), "$options": "i"}},
                {"lastname": {"$regex": re.escape(word), "$options": "i"}},
                {"username": {"$regex": re.escape(word), "$options": "i"}},
            ]}
            for word in words
        ]}
        total = await self.count(query)
        users = await self.find_page(query, skip=skip, limit=limit)
        return users, total
