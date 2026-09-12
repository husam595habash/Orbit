from repositories.comment_repository import CommentRepository
from repositories.conversation_read_state_repository import ConversationReadStateRepository
from repositories.message_repository import MessageRepository
from repositories.notification_repository import NotificationRepository
from repositories.post_repository import PostRepository
from repositories.user_repository import UserRepository

from services.chat import ChatService
from services.comment import CommentService
from services.notification import NotificationService
from services.post import PostService
from services.user import UserService


def get_notification_service() -> NotificationService:
    return NotificationService(notification_repository=NotificationRepository())


def get_user_service() -> UserService:
    return UserService(
        user_repository=UserRepository(),
        notification_service=get_notification_service(),
    )


def get_comment_service() -> CommentService:
    return CommentService(
        comment_repository=CommentRepository(),
        post_repository=PostRepository(),
        user_repository=UserRepository(),
        notification_service=get_notification_service(),
    )


def get_post_service() -> PostService:
    return PostService(
        post_repository=PostRepository(),
        user_repository=UserRepository(),
        notification_service=get_notification_service(),
        comment_service=get_comment_service(),
    )


def get_chat_service() -> ChatService:
    return ChatService(
        message_repository=MessageRepository(),
        conversation_read_state_repository=ConversationReadStateRepository(),
        user_service=get_user_service(),
    )
