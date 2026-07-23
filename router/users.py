from typing import Optional

from auth.auth_bearer import JWTBearer
from auth.auth_handler import decodeJWT
from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse
from pymongo.errors import DuplicateKeyError
from services.user import UserService
from interface.user import CreateUser, LoginUser, UpdateUser

users_router = APIRouter()

# register a new user
@users_router.post("/signup", status_code=status.HTTP_201_CREATED)
async def signup(user: CreateUser, user_Service: UserService = Depends()):
    try:
        result = await user_Service.create_user(user)
        return {
            "user": result["user"].model_dump(mode="json", exclude={"password"}),
            "token": result["token"],
        }
    except DuplicateKeyError:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "User already exists"})


# login a user
@users_router.post("/login", status_code=status.HTTP_200_OK)
async def login(user: LoginUser, user_Service: UserService = Depends()):
    result = await user_Service.authenticate_user(user)
    if not result:
        return JSONResponse(
            status_code=status.HTTP_401_UNAUTHORIZED,
            content={"message": "Invalid email or password"})
    return {
        "user": result["user"].model_dump(mode="json", exclude={"password"}),
        "token": result["token"],
    }


# get Suggested Users
@users_router.get("/suggested", status_code=status.HTTP_200_OK)
async def get_suggested_users(id: Optional[str] = None, user_service: UserService = Depends()):
    if not id:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "id is required"}
        )
    try:
        result = await user_service.get_suggested_users(id)
    except Exception:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "Failed to get suggested users"}
        )
    if not result:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"message": "User not found"}
        )
    return {
        "users": [u.model_dump(mode="json", exclude={"password"}) for u in result["users"]]
    }


# get user by id
@users_router.get("/{user_id}", status_code=status.HTTP_200_OK)
async def getUser(user_id: str, user_service: UserService = Depends()):
    result = await user_service.get_user_by_id(user_id)
    if not result:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"message": "User not found"}
        )
    return {
        "user": result["user"].model_dump(mode="json", exclude={"password"}),
        "posts": result["posts"],
    }


@users_router.patch("/{user_id}", status_code=status.HTTP_200_OK)
async def update_user(
    userBody: UpdateUser,
    user_id: str,
    user_service: UserService = Depends(),
    token: str = Depends(JWTBearer()),
):
    try:
        uid = decodeJWT(token)["user_id"]
        if uid != user_id:
            return JSONResponse(
                status_code=status.HTTP_403_FORBIDDEN,
                content={"message": "You are not authorized to update this user"}
            )
        result = await user_service.update_user(userBody, user_id)
    except Exception:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "Failed to update user"}
        )
    if not result:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"message": "User not found"}
        )
    return {
        "user": result["user"].model_dump(mode="json", exclude={"password"}),
        "posts": result["posts"],
    }


@users_router.patch("/{user_id}/following/{target_id}", status_code=status.HTTP_200_OK)
async def follow_user(
    user_id: str,
    target_id: str,
    user_service: UserService = Depends(),
    token: str = Depends(JWTBearer()),
):
    uid = decodeJWT(token)["user_id"]
    if uid != user_id:
        return JSONResponse(
            status_code=status.HTTP_403_FORBIDDEN,
            content={"message": "You are not authorized to modify this user's following list"}
        )
    try:
        result = await user_service.follow_user(user_id, target_id)
    except Exception:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "Failed to follow user"}
        )
    if not result:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"message": "User not found"}
        )
    return {
        "user1": result["user1"].model_dump(mode="json", exclude={"password"}),
        "user2": result["user2"].model_dump(mode="json", exclude={"password"}),
    }


@users_router.delete("/delete/{user_id}", status_code=status.HTTP_200_OK)
async def delete_user(
    user_id: str,
    user_service: UserService = Depends(),
    token: str = Depends(JWTBearer()),
):
    uid = decodeJWT(token)["user_id"]
    if uid != user_id:
        return JSONResponse(
            status_code=status.HTTP_403_FORBIDDEN,
            content={"message": "You are not authorized to delete this user"}
        )
    try:
        result = await user_service.delete_user(user_id)
    except Exception:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "Failed to delete user"}
        )
    if not result:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"message": "User not found"}
        )
    return {
        "message": "User deleted successfully"
    }