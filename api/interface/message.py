from pydantic import BaseModel

class CreateMessage(BaseModel):
    content: str
    receiver: str