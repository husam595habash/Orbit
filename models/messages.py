from beanie import Document

class Message(Document):
    content: str
    sender: str
    receiver: str
    class Settings:
        collection = "messages"
