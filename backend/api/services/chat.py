import logging
import math

from models.message import Message
from models.conversation_read_state import ConversationReadState
from schemas.message import CreateMessage

logger = logging.getLogger(__name__)


class ChatService:

    # send a message
    @staticmethod
    async def send_message(msg: CreateMessage, sender_id: str):
        try:
            msg_in = Message(
                content=msg.content,
                sender=sender_id,
                receiver=msg.receiver
            )
            await msg_in.save()
            await ChatService.update_unread_message(sender_id, msg.receiver)
            return {"message": msg_in}
        except Exception as e:
            logger.error(e)
            return None
        


    # update unread message
    @staticmethod
    async def update_unread_message(sender: str, receiver: str):
        try:
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
        except Exception as e:
            logger.error(e)
            return None
        
    
    # get conversation messages, paginated
    @staticmethod
    async def get_conversation_messages(page: str, user_a_id: str, user_b_id: str):
        try:
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
        except Exception as e:
            logger.error(e)
            return None
        


    # get user unread messages
    @staticmethod
    async def get_user_unread_messages(user_id: str):
        try:
            unread_records = await ConversationReadState.find({"recipient_id": user_id, "isRead": False}).to_list()
            total_unread_messages = sum(record.numOfUnreadMessages for record in unread_records)

            return {"messages": [record.model_dump(mode="json") for record in unread_records], "total": total_unread_messages}
        except Exception as e:
            logger.error(e)
            return None


    # mark messages as read
    @staticmethod
    async def mark_messages_as_read(recipient_id: str, sender_id: str):
        try:
            read_filter = {"recipient_id": recipient_id, "sender_id": sender_id}
            update = {"$set": {"isRead": True, "numOfUnreadMessages": 0}}

            result = await ConversationReadState.find_one(read_filter)
            if not result:
                return {"isMarked": False}

            await result.update(update)
            return {"isMarked": True}
        except Exception as e:
            logger.error(e)
            return None
