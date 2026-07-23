from fastapi import APIRouter
from router.users import users_router
from router.posts import posts_router

router = APIRouter()

router.include_router(users_router, prefix="/user", tags=["users"])
router.include_router(posts_router, prefix="/post", tags=["posts"])