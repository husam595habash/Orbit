from models.users import User
from passlib.context import CryptContext
from interface.user import CreateUser, LoginUser, UpdateUser
from typing import Optional
from bson import ObjectId
from auth.auth_handler import signJWT


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class UserService:
    @staticmethod
    async def create_user(user: CreateUser):
        try:
            user_in= User(
                name= user.name,
                lastname= user.lastname,
                email= user.email,
                password= pwd_context.hash(user.password)
            )

            created_user = await user_in.save()  # Save the user to the database
            token = signJWT(str(created_user.id))
            return {"user": created_user, "token": token["access_token"]}
        except Exception as e:
            print(f"Error creating user: {e}")
            raise
    

    # get user by email
    @staticmethod
    async def get_user_by_email(email: str) -> Optional[User]:
        user = await User.find_one(User.email == email)
        return user
    
    # login user
    @staticmethod
    async def authenticate_user(userBody: LoginUser) -> Optional[User]:
        user = await UserService.get_user_by_email(email = userBody.email)
        if not user:
            return None
        if not pwd_context.verify(userBody.password, user.password):
            return None
        
        token = signJWT(str(user.id))
        return {"user": user, "token": token["access_token"]}

    @staticmethod
    async def get_user_by_id(user_id: str) -> Optional[dict]:
        try:
            user = await User.find_one({"_id": ObjectId(user_id)})
        except Exception:
            return None
        if not user:
            return None
        return {"user": user, "posts": "posts"}
    


    #update user
    @staticmethod
    async def update_user(userBody: UpdateUser, id: str) -> Optional[dict]:
        try:
            user = await User.find_one({"_id": ObjectId(id)})
        except Exception:
            return None
        if not user:
            return None

        if userBody.name is not None:
            user.name = userBody.name
        if userBody.lastname is not None:
            user.lastname = userBody.lastname
        if userBody.password is not None:
            user.password = pwd_context.hash(userBody.password)
        if userBody.Bio is not None:
            user.bio = userBody.Bio
        if userBody.image is not None:
            user.imageUrl = userBody.image
        await user.save()

        # TODO: Return user posts
        return {"user": user, "posts": "posts"}