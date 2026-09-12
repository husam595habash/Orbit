from typing import Optional

from auth.auth_bearer import get_current_user_id
from di import get_notification_service
from services.notification import NotificationService

from fastapi import APIRouter, Depends, status

notifications_router = APIRouter()

@notifications_router.get("", status_code=status.HTTP_200_OK)
async def get_user_notifications(
    page: Optional[str] = None,
    user_id: str = Depends(get_current_user_id),
    notification_service: NotificationService = Depends(get_notification_service),
):
    return await notification_service.get_user_notifications(user_id, page)


@notifications_router.patch("/read", status_code=status.HTTP_200_OK)
async def mark_notifications_as_read(
    page: Optional[str] = None,
    user_id: str = Depends(get_current_user_id),
    notification_service: NotificationService = Depends(get_notification_service),
):
    return await notification_service.mark_notifications_as_read(user_id, page)
