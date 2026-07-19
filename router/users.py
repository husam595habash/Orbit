from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse
from pymongo.errors import DuplicateKeyError
from services.user import UserService
from interface.user import CreateUser

users_router = APIRouter()

# register a new user
@users_router.post("/signup", status_code=status.HTTP_201_CREATED)
async def signup(user: CreateUser, user_Service: UserService = Depends()):
    try:
        new_user = await user_Service.create_user(user)
        return new_user.model_dump(mode="json", exclude={"password"})
    except DuplicateKeyError:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "User already exists"})