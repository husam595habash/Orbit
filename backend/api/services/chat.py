import math

from exceptions import NotFoundError
from models.message import Message
from models.conversation_read_state import ConversationReadState
from schemas.message import CreateMessage
from repositories.conversation_read_state_repository import ConversationReadStateRepository
from repositories.message_repository import MessageRepository
from services.user import UserService


class ChatService:

    def __init__(
        self,
        message_repository: MessageRepository,
        conversation_read_state_repository: ConversationReadStateRepository,
        user_service: UserService,
    ):
        self.message_repository = message_repository
        self.conversation_read_state_repository = conversation_read_state_repository
        self.user_service = user_service

    # send a message
    async def send_message(self, msg: CreateMessage, sender_id: str):
        msg_in = Message(
            content=msg.content,
            sender=sender_id,
            receiver=msg.receiver
        )
        await self.message_repository.save(msg_in)
        await self.update_unread_message(sender_id, msg.receiver)
        return {"message": msg_in.model_dump(mode="json")}


    # update unread message
    async def update_unread_message(self, sender: str, receiver: str):
        existing_record = await self.conversation_read_state_repository.find_for_pair(receiver, sender)
        if existing_record:
            await self.conversation_read_state_repository.increment_unread(existing_record)
        else:
            new_unread_msg = ConversationReadState(
                recipient_id=receiver,
                sender_id=sender,
                numOfUnreadMessages=1,
                isRead=False,
            )
            await self.conversation_read_state_repository.insert(new_unread_msg)


    # get conversation messages, paginated
    async def get_conversation_messages(self, page: str, user_a_id: str, user_b_id: str):
        limit = 8
        page_num = int(page) if page and page.isdigit() else 0

        messages, total = await self.message_repository.find_conversation_page(
            user_a_id, user_b_id, skip=page_num * limit, limit=limit
        )

        messages.reverse()

        return {
            "messages": [m.model_dump(mode="json") for m in messages],
            "currentPage": page_num,
            "numberOfPages": math.ceil(total / limit) if total else 0
        }



    # get user unread messages
    async def get_user_unread_messages(self, user_id: str):
        unread_records = await self.conversation_read_state_repository.find_unread_for_recipient(user_id)
        total_unread_messages = sum(record.numOfUnreadMessages for record in unread_records)

        return {"messages": [record.model_dump(mode="json") for record in unread_records], "total": total_unread_messages}


    # list the current user's conversation threads — one entry per partner,
    # newest message first, with the partner's display info and unread count
    # attached so the inbox screen doesn't need a fetch per row.
    async def get_conversations(self, user_id: str):
        # Find the most recent message per conversation partner inside
        # MongoDB itself, instead of pulling the user's entire message
        # history into app memory and grouping it in Python.
        latest_per_partner = await self.message_repository.find_latest_per_partner(user_id)

        unread_records = await self.conversation_read_state_repository.find_unread_for_recipient(user_id)
        unread_by_sender = {r.sender_id: r.numOfUnreadMessages for r in unread_records}

        conversations = []
        for entry in latest_per_partner:
            partner_id = entry["_id"]

            try:
                partner = await self.user_service.get_user_by_id(partner_id)
            except NotFoundError:
                continue

            full_name = f"{partner.firstname} {partner.lastname}".strip()
            conversations.append({
                "partnerId": partner_id,
                "partnerName": full_name or partner.username,
                "partnerUsername": partner.username,
                "partnerImageUrl": partner.imageUrl,
                "lastMessage": entry["lastMessageContent"],
                "lastMessageId": str(entry["lastMessageId"]),
                "unreadCount": unread_by_sender.get(partner_id, 0),
            })

        return {"conversations": conversations}


    # mark messages as read
    async def mark_messages_as_read(self, recipient_id: str, sender_id: str):
        record = await self.conversation_read_state_repository.find_for_pair(recipient_id, sender_id)
        if not record:
            raise NotFoundError("No unread conversation found")

        await self.conversation_read_state_repository.mark_read(record)
        return {"isMarked": True}
