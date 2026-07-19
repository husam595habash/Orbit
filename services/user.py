from models.users import User
from passlib.context import CryptContext
from interface.user import CreateUser, LoginUser
from typing import Optional

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
            # TODO : create a token for the user
        except Exception as e:
            print(f"Error creating user: {e}")
            raise
        return created_user
    

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
        
        # TODO : create a token for the user
        return {"user": user, "token": "token"}


