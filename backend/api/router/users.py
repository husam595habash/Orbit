from typing import Optional

from auth.auth_bearer import get_current_user_id
from di import get_user_service
from fastapi import APIRouter, Depends, Request, status
from pymongo.errors import DuplicateKeyError
from exceptions import ForbiddenError, ValidationError
from rate_limit import limiter
from services.user import UserService
from schemas.user import CreateUser, LoginUser, UpdateUser, GoogleAuthRequest
from fastapi.responses import JSONResponse

users_router = APIRouter()

# register a new user
@users_router.post("/signup", status_code=status.HTTP_201_CREATED)
@limiter.limit("5/minute")
async def signup(request: Request, user: CreateUser, user_service: UserService = Depends(get_user_service)):
    try:
        result = await user_service.create_user(user)
    except DuplicateKeyError:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "User already exists"})
    return result


# login a user
@users_router.post("/login", status_code=status.HTTP_200_OK)
@limiter.limit("10/minute")
async def login(request: Request, user: LoginUser, user_service: UserService = Depends(get_user_service)):
    return await user_service.authenticate_user(user)

@users_router.post("/auth/google", status_code=status.HTTP_200_OK)
async def google_auth(
    request: Request,
    token: GoogleAuthRequest,
    user_service: UserService = Depends(get_user_service)
):
    return await user_service.authenticate_google_user(token.id_token)


# get Suggested Users
@users_router.get("/suggested", status_code=status.HTTP_200_OK)
async def get_suggested_users(
    uid: str = Depends(get_current_user_id),
    user_service: UserService = Depends(get_user_service),
):
    return await user_service.get_suggested_users(uid)


# search users by first name, last name, or username
@users_router.get("/search", status_code=status.HTTP_200_OK)
async def search_users(
    q: Optional[str] = None,
    page: Optional[str] = None,
    user_service: UserService = Depends(get_user_service),
):
    if not q:
        raise ValidationError("q is required")
    return await user_service.search_users(q, page)


# get user by id
@users_router.get("/{user_id}", status_code=status.HTTP_200_OK)
async def getUser(user_id: str, user_service: UserService = Depends(get_user_service)):
    return await user_service.get_user_profile(user_id)


@users_router.patch("/{user_id}", status_code=status.HTTP_200_OK)
async def update_user(
    userBody: UpdateUser,
    user_id: str,
    user_service: UserService = Depends(get_user_service),
    uid: str = Depends(get_current_user_id),
):
    if uid != user_id:
        raise ForbiddenError("You are not authorized to update this user")

    return await user_service.update_user(userBody, user_id)



@users_router.patch("/{user_id}/following/{target_id}", status_code=status.HTTP_200_OK)
@limiter.limit("30/minute")
async def follow_user(
    request: Request,
    user_id: str,
    target_id: str,
    user_service: UserService = Depends(get_user_service),
    uid: str = Depends(get_current_user_id),
):
    if uid != user_id:
        raise ForbiddenError("You are not authorized to modify this user's following list")

    return await user_service.follow_user(user_id, target_id)


@users_router.get("/{user_id}/followers", status_code=status.HTTP_200_OK)
async def get_followers(user_id: str, page: Optional[str] = None, user_service: UserService = Depends(get_user_service)):
    return await user_service.get_followers(user_id, page)


@users_router.get("/{user_id}/following", status_code=status.HTTP_200_OK)
async def get_following(user_id: str, page: Optional[str] = None, user_service: UserService = Depends(get_user_service)):
    return await user_service.get_following(user_id, page)


@users_router.delete("/{user_id}", status_code=status.HTTP_200_OK)
async def delete_user(
    user_id: str,
    user_service: UserService = Depends(get_user_service),
    uid: str = Depends(get_current_user_id),
):
    if uid != user_id:
        raise ForbiddenError("You are not authorized to delete this user")

    return await user_service.delete_user(user_id)
