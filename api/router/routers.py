from fastapi import APIRouter
from router.users import users_router
from router.posts import posts_router
from router.chat import chat_router
from router.notifications import notifications_router
from router.comments import comments_router


router = APIRouter()

router.include_router(users_router, prefix="/user", tags=["users"])
router.include_router(posts_router, prefix="/post", tags=["posts"])
router.include_router(chat_router, prefix="/chat", tags=["chat"])
router.include_router(notifications_router, prefix="/notification", tags=["notifications"])
router.include_router(comments_router, prefix="/comment", tags=["comments"])
