from fastapi import APIRouter
from router.users import users_router

router = APIRouter()

router.include_router(users_router, prefix="/user", tags=["users"])