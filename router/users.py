from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse
from pymongo.errors import DuplicateKeyError
from services.user import UserService
from interface.user import CreateUser, LoginUser

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