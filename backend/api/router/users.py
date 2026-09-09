from typing import Optional

from auth.auth_bearer import get_current_user_id
from fastapi import APIRouter, Depends, status
from pymongo.errors import DuplicateKeyError
from exceptions import ForbiddenError, NotFoundError, ValidationError
from services.user import UserService
from schemas.user import CreateUser, LoginUser, UpdateUser
from fastapi.responses import JSONResponse

users_router = APIRouter()

# register a new user
@users_router.post("/signup", status_code=status.HTTP_201_CREATED)
async def signup(user: CreateUser, user_service: UserService = Depends()):
    try:
        result = await user_service.create_user(user)
    except DuplicateKeyError:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "User already exists"})
    return {
        "user": result["user"].model_dump(mode="json", exclude={"password"}),
        "token": result["token"],
    }


# login a user
@users_router.post("/login", status_code=status.HTTP_200_OK)
async def login(user: LoginUser, user_service: UserService = Depends()):
    result = await user_service.authenticate_user(user)
    return {
        "user": result["user"].model_dump(mode="json", exclude={"password"}),
        "token": result["token"],
    }


# get Suggested Users
@users_router.get("/suggested", status_code=status.HTTP_200_OK)
async def get_suggested_users(
    uid: str = Depends(get_current_user_id),
    user_service: UserService = Depends(),
):
    result = await user_service.get_suggested_users(uid)
    if not result:
        raise NotFoundError("User not found")
    return {
        "users": [u.model_dump(mode="json", exclude={"password"}) for u in result["users"]]
    }


# search users by first name, last name, or username
@users_router.get("/search", status_code=status.HTTP_200_OK)
async def search_users(
    q: Optional[str] = None,
    page: Optional[str] = None,
    user_service: UserService = Depends(),
):
    if not q:
        raise ValidationError("q is required")
    result = await user_service.search_users(q, page)
    return {
        "users": [u.model_dump(mode="json", exclude={"password"}) for u in result["users"]],
        "currentPage": result["currentPage"],
        "hasMore": result["hasMore"],
    }


# get user by id
@users_router.get("/{user_id}", status_code=status.HTTP_200_OK)
async def getUser(user_id: str, user_service: UserService = Depends()):
    result = await user_service.get_user_by_id(user_id)
    if not result:
        raise NotFoundError("User not found")
    return result.model_dump(mode="json", exclude={"password"})


@users_router.patch("/{user_id}", status_code=status.HTTP_200_OK)
async def update_user(
    userBody: UpdateUser,
    user_id: str,
    user_service: UserService = Depends(),
    uid: str = Depends(get_current_user_id),
):
    if uid != user_id:
        raise ForbiddenError("You are not authorized to update this user")

    result = await user_service.update_user(userBody, user_id)
    if not result:
        raise NotFoundError("User not found")
    return result.model_dump(mode="json", exclude={"password"})


@users_router.patch("/{user_id}/following/{target_id}", status_code=status.HTTP_200_OK)
async def follow_user(
    user_id: str,
    target_id: str,
    user_service: UserService = Depends(),
    uid: str = Depends(get_current_user_id),
):
    if uid != user_id:
        raise ForbiddenError("You are not authorized to modify this user's following list")

    result = await user_service.follow_user(user_id, target_id)
    if not result:
        raise NotFoundError("User not found")
    return {
        "user1": result["user1"].model_dump(mode="json", exclude={"password"}),
        "user2": result["user2"].model_dump(mode="json", exclude={"password"}),
    }


@users_router.get("/{user_id}/followers", status_code=status.HTTP_200_OK)
async def get_followers(user_id: str, user_service: UserService = Depends()):
    result = await user_service.get_followers(user_id)
    if result is None:
        raise NotFoundError("User not found")
    return {
        "users": [u.model_dump(mode="json", exclude={"password"}) for u in result]
    }


@users_router.get("/{user_id}/following", status_code=status.HTTP_200_OK)
async def get_following(user_id: str, user_service: UserService = Depends()):
    result = await user_service.get_following(user_id)
    if result is None:
        raise NotFoundError("User not found")
    return {
        "users": [u.model_dump(mode="json", exclude={"password"}) for u in result]
    }


@users_router.delete("/{user_id}", status_code=status.HTTP_200_OK)
async def delete_user(
    user_id: str,
    user_service: UserService = Depends(),
    uid: str = Depends(get_current_user_id),
):
    if uid != user_id:
        raise ForbiddenError("You are not authorized to delete this user")

    result = await user_service.delete_user(user_id)
    if not result:
        raise NotFoundError("User not found")
    return {
        "message": "User deleted successfully"
    }
