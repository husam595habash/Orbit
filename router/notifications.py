from typing import Optional

from auth.auth_bearer import JWTBearer
from auth.auth_handler import decodeJWT
from services.notification import NotificationService

from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse

notification_router = APIRouter()

@notification_router.get("", status_code=status.HTTP_200_OK)
async def get_user_notifications(
    token: str = Depends(JWTBearer()),
    notification_service: NotificationService = Depends(),
):
    user_id = decodeJWT(token)["user_id"]
    result = await notification_service.get_user_notifications(user_id)
    if result is None:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "Failed to get notifications"}
        )
    return result


@notification_router.patch("/read", status_code=status.HTTP_200_OK)
async def mark_notifications_as_read(
    token: str = Depends(JWTBearer()),
    notification_service: NotificationService = Depends(),
):
    user_id = decodeJWT(token)["user_id"]
    result = await notification_service.mark_notifications_as_read(user_id)
    if not result:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "Failed to mark notifications as read"}
        )
    return result