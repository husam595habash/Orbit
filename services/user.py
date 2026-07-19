from models.users import User
from passlib.context import CryptContext
from interface.user import CreateUser

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
