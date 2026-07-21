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
    

    # follow user
    @staticmethod
    async def follow_user(user_id: str, target_user_id: str) -> Optional[dict]:
        try:
            user1 = await User.find_one({"_id": ObjectId(user_id)})
            user2 = await User.find_one({"_id": ObjectId(target_user_id)})
        except Exception:
            return None
        if not user1 or not user2:
            return None

        # check if user1 is already following user2
        if target_user_id in user1.following:
            user1.following.remove(target_user_id)
            user2.followers.remove(user_id)
        else:
            user1.following.append(target_user_id)
            user2.followers.append(user_id)
            # TODO: add notification to user2 that user1 followed them
        await user1.save()
        await user2.save()

        return {"user1": user1, "user2": user2}
    

    # get some suggested users to follow
    @staticmethod
    async def get_suggested_users(user_id: str) -> Optional[dict]:
        try:
            main_user = await User.find_one({"_id": ObjectId(user_id)})
        except Exception:
            return None
        if not main_user:
            return None

        # don't suggest yourself or people you already follow
        exclude_ids = {str(main_user.id), *main_user.following}
        suggestions = []

        for followed_id in main_user.following:
            followed_user = await User.find_one({"_id": ObjectId(followed_id)})
            if not followed_user:
                continue

            related_ids = followed_user.followers + followed_user.following
            for related_id in related_ids:
                if related_id in exclude_ids:
                    continue
                exclude_ids.add(related_id)

                related_user = await User.find_one({"_id": ObjectId(related_id)})
                if related_user:
                    suggestions.append(related_user)

        return {"users": suggestions}