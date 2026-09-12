from models.message import Message
from repositories.base import BaseRepository


class MessageRepository(BaseRepository[Message]):
    model = Message

    async def find_conversation_page(self, user_a_id: str, user_b_id: str, skip: int, limit: int) -> tuple[list[Message], int]:
        query = {"$or": [
            {"sender": user_a_id, "receiver": user_b_id},
            {"sender": user_b_id, "receiver": user_a_id},
        ]}
        total = await self.count(query)
        messages = await self.find_page(query, skip=skip, limit=limit, sort=-Message.id)
        return messages, total

    async def find_latest_per_partner(self, user_id: str) -> list[dict]:
        pipeline = [
            {"$match": {"$or": [{"sender": user_id}, {"receiver": user_id}]}},
            {"$sort": {"_id": -1}},
            {
                "$group": {
                    "_id": {"$cond": [{"$eq": ["$sender", user_id]}, "$receiver", "$sender"]},
                    "lastMessageContent": {"$first": "$content"},
                    "lastMessageId": {"$first": "$_id"},
                }
            },
            {"$sort": {"lastMessageId": -1}},
        ]
        return await Message.aggregate(pipeline).to_list()
