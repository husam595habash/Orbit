from beanie import init_beanie
from models.user import User
from models.post import Post
from models.message import Message
from models.conversation_read_state import ConversationReadState
from models.notification import Notification
from models.comment import Comment


async def init_db():
    await init_beanie(
        connection_string="mongodb://localhost:27017/social",
        document_models=[User, Post, Message, ConversationReadState, Notification, Comment]
    )