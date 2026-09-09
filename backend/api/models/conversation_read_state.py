from beanie import Document

class ConversationReadState(Document):
    recipient_id: str
    sender_id: str
    numOfUnreadMessages: int
    isRead: bool
    class Settings:
        name = "conversation_read_states"
        indexes = [[("recipient_id", 1), ("sender_id", 1)]]
