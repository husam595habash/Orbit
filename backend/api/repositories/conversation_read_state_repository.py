from typing import Optional

from models.conversation_read_state import ConversationReadState
from repositories.base import BaseRepository


class ConversationReadStateRepository(BaseRepository[ConversationReadState]):
    model = ConversationReadState

    async def find_for_pair(self, recipient_id: str, sender_id: str) -> Optional[ConversationReadState]:
        return await ConversationReadState.find_one({"recipient_id": recipient_id, "sender_id": sender_id})

    async def find_unread_for_recipient(self, recipient_id: str) -> list[ConversationReadState]:
        return await ConversationReadState.find({"recipient_id": recipient_id, "isRead": False}).to_list()

    async def increment_unread(self, record: ConversationReadState) -> None:
        await record.update({"$inc": {"numOfUnreadMessages": 1}, "$set": {"isRead": False}})

    async def mark_read(self, record: ConversationReadState) -> None:
        await record.update({"$set": {"isRead": True, "numOfUnreadMessages": 0}})
