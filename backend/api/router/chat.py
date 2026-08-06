from typing import Optional

from services.chat import ChatService
from schemas.message import CreateMessage
from auth.auth_bearer import JWTBearer
from auth.auth_handler import decodeJWT

from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse

chat_router = APIRouter()

@chat_router.post("/messages", status_code=status.HTTP_201_CREATED)
async def send_message(
    data: CreateMessage,
    token: str = Depends(JWTBearer()),
    chat_service: ChatService = Depends(),
):
    sender_id = decodeJWT(token)["user_id"]
    result = await chat_service.send_message(data, sender_id)
    if not result:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "Failed to send message"}
        )
    return result["message"].model_dump(mode="json")



@chat_router.get("/messages")
async def get_conversation_messages(
    user_a_id: str,
    user_b_id: str,
    page: str = "0",
    token: str = Depends(JWTBearer()),
    chat_service: ChatService = Depends(),
):
    uid = decodeJWT(token)["user_id"]
    if uid not in (user_a_id, user_b_id):
        return JSONResponse(
            status_code=status.HTTP_403_FORBIDDEN,
            content={"message": "You are not authorized to view this conversation"}
        )

    result = await chat_service.get_conversation_messages(page, user_a_id, user_b_id)
    if not result:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "Failed to get messages"}
        )
    return {
        "messages": [m.model_dump(mode="json") for m in result["messages"]],
        "currentPage": result["currentPage"],
        "numberOfPages": result["numberOfPages"],
    }


@chat_router.get("/conversations")
async def get_conversations(
    token: str = Depends(JWTBearer()),
    chat_service: ChatService = Depends(),
):
    uid = decodeJWT(token)["user_id"]
    result = await chat_service.get_conversations(uid)
    if result is None:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "Failed to get conversations"}
        )
    return {"conversations": result}


@chat_router.get("/messages/unread")
async def get_user_unread_messages(
    token: str = Depends(JWTBearer()),
    chat_service: ChatService = Depends(),
):
    uid = decodeJWT(token)["user_id"]
    result = await chat_service.get_user_unread_messages(uid)
    if not result:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "Failed to get unread messages"}
        )
    return result


@chat_router.patch("/messages/read")
async def mark_messages_as_read(
    sender_id: str,
    token: str = Depends(JWTBearer()),
    chat_service: ChatService = Depends(),
):
    recipient_id = decodeJWT(token)["user_id"]
    result = await chat_service.mark_messages_as_read(recipient_id, sender_id)
    if not result:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "Failed to mark messages as read"}
        )
    return result