from beanie import Document

class Message(Document):
    content: str
    sender: str
    receiver: str
    class Settings:
        name = "messages"
        indexes = [
            [("sender", 1), ("receiver", 1), ("_id", -1)],
            [("receiver", 1), ("sender", 1), ("_id", -1)],
        ]
