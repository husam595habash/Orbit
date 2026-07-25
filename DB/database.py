from beanie import init_beanie
from models.users import User
from models.posts import Post
from models.messages import Message
from models.conversation_read_state import ConversationReadState


async def init_db():
    await init_beanie(
        connection_string="mongodb://localhost:27017/social",
        document_models=[User, Post, Message, ConversationReadState]
    )