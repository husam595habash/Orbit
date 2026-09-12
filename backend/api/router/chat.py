from di import get_chat_service
from services.chat import ChatService
from schemas.message import CreateMessage
from auth.auth_bearer import get_current_user_id
from exceptions import ForbiddenError

from fastapi import APIRouter, Depends, status

chat_router = APIRouter()

@chat_router.post("/messages", status_code=status.HTTP_201_CREATED)
async def send_message(
    data: CreateMessage,
    sender_id: str = Depends(get_current_user_id),
    chat_service: ChatService = Depends(get_chat_service),
):
    return await chat_service.send_message(data, sender_id)



@chat_router.get("/messages")
async def get_conversation_messages(
    user_a_id: str,
    user_b_id: str,
    page: str = "0",
    uid: str = Depends(get_current_user_id),
    chat_service: ChatService = Depends(get_chat_service),
):
    if uid not in (user_a_id, user_b_id):
        raise ForbiddenError("You are not authorized to view this conversation")

    return await chat_service.get_conversation_messages(page, user_a_id, user_b_id)


@chat_router.get("/conversations")
async def get_conversations(
    uid: str = Depends(get_current_user_id),
    chat_service: ChatService = Depends(get_chat_service),
):
    return await chat_service.get_conversations(uid)


@chat_router.get("/messages/unread")
async def get_user_unread_messages(
    uid: str = Depends(get_current_user_id),
    chat_service: ChatService = Depends(get_chat_service),
):
    return await chat_service.get_user_unread_messages(uid)


@chat_router.patch("/messages/read")
async def mark_messages_as_read(
    sender_id: str,
    recipient_id: str = Depends(get_current_user_id),
    chat_service: ChatService = Depends(get_chat_service),
):
    return await chat_service.mark_messages_as_read(recipient_id, sender_id)
