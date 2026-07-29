from beanie import Document

class ConversationReadState(Document):
    recipient_id: str
    sender_id: str
    numOfUnreadMessages: int
    isRead: bool
    class Settings:
        collection = "conversation_read_states"
