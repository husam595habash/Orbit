from typing import Optional

from services.chat import ChatService
from interface.message import CreateMessage
from auth.auth_bearer import JWTBearer
from auth.auth_handler import decodeJWT

from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse

chat_router = APIRouter()

@chat_router.post("/sendMessage", status_code=status.HTTP_201_CREATED)
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