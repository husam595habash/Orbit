from beanie import Document

class ConversationReadState(Document):
    recipientID: str
    senderID: str
    numOfUnreadMessages: int
    isRead: bool
    class Settings:
        collection = "conversation_read_states"
