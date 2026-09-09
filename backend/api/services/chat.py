import math

from fastapi import Depends

from exceptions import NotFoundError
from models.message import Message
from models.conversation_read_state import ConversationReadState
from schemas.message import CreateMessage
from services.user import UserService


class ChatService:

    def __init__(self, user_service: UserService = Depends()):
        self.user_service = user_service

    # send a message
    async def send_message(self, msg: CreateMessage, sender_id: str):
        msg_in = Message(
            content=msg.content,
            sender=sender_id,
            receiver=msg.receiver
        )
        await msg_in.save()
        await self.update_unread_message(sender_id, msg.receiver)
        return {"message": msg_in}



    # update unread message
    async def update_unread_message(self, sender: str, receiver: str):
        existing_record = await ConversationReadState.find_one({"recipient_id": receiver, "sender_id": sender})
        if existing_record:
            await existing_record.update({"$inc": {"numOfUnreadMessages": 1}, "$set": {"isRead": False}})
        else:
            new_unread_msg = ConversationReadState(
                recipient_id=receiver,
                sender_id=sender,
                numOfUnreadMessages=1,
                isRead=False,
            )
            await new_unread_msg.insert()


    # get conversation messages, paginated
    async def get_conversation_messages(self, page: str, user_a_id: str, user_b_id: str):
        query = {"$or": [
            {"sender": str(user_a_id), "receiver": str(user_b_id)},
            {"sender": str(user_b_id), "receiver": str(user_a_id)},
        ]}

        limit = 8
        page_num = int(page) if page and page.isdigit() else 0
        total = await Message.find(query).count()
        messages = await Message.find(query) \
            .sort(-Message.id).limit(limit).skip(page_num * limit).to_list()

        messages.reverse()

        return {
            "messages": messages,
            "currentPage": page_num,
            "numberOfPages": math.ceil(total / limit) if total else 0
        }



    # get user unread messages
    async def get_user_unread_messages(self, user_id: str):
        unread_records = await ConversationReadState.find({"recipient_id": user_id, "isRead": False}).to_list()
        total_unread_messages = sum(record.numOfUnreadMessages for record in unread_records)

        return {"messages": [record.model_dump(mode="json") for record in unread_records], "total": total_unread_messages}


    # list the current user's conversation threads — one entry per partner,
    # newest message first, with the partner's display info and unread count
    # attached so the inbox screen doesn't need a fetch per row.
    async def get_conversations(self, user_id: str):
        # Find the most recent message per conversation partner inside
        # MongoDB itself, instead of pulling the user's entire message
        # history into app memory and grouping it in Python.
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
        latest_per_partner = await Message.aggregate(pipeline).to_list()

        unread_records = await ConversationReadState.find(
            {"recipient_id": user_id, "isRead": False}
        ).to_list()
        unread_by_sender = {r.sender_id: r.numOfUnreadMessages for r in unread_records}

        conversations = []
        for entry in latest_per_partner:
            partner_id = entry["_id"]

            partner = await self.user_service.get_user_by_id(partner_id)
            if not partner:
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

        return conversations


    # mark messages as read
    async def mark_messages_as_read(self, recipient_id: str, sender_id: str):
        read_filter = {"recipient_id": recipient_id, "sender_id": sender_id}
        update = {"$set": {"isRead": True, "numOfUnreadMessages": 0}}

        result = await ConversationReadState.find_one(read_filter)
        if not result:
            raise NotFoundError("No unread conversation found")

        await result.update(update)
        return {"isMarked": True}
