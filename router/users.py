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
        new_user = await user_Service.create_user(user)
        return new_user.model_dump(mode="json", exclude={"password"})
    except DuplicateKeyError:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "User already exists"})
    

# login a user
@users_router.post("/login", status_code=status.HTTP_200_OK)
async def login(user: LoginUser, user_Service: UserService = Depends()):
    user = await user_Service.authenticate_user(user)
    if not user:
        return JSONResponse(
            status_code=status.HTTP_401_UNAUTHORIZED,
            content={"message": "Invalid email or password"})
    return user