import logging
import re
from models.user import User
from passlib.context import CryptContext
from schemas.user import CreateUser, LoginUser, UpdateUser
from typing import Optional
from bson import ObjectId
from auth.auth_handler import signJWT
from services.notification import NotificationService


logger = logging.getLogger(__name__)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class UserService:
    @staticmethod
    async def create_user(user: CreateUser):
        try:
            user_in= User(
                firstname= user.firstname,
                lastname= user.lastname,
                username= user.username,
                email= user.email,
                password= pwd_context.hash(user.password)
            )

            created_user = await user_in.save()  # Save the user to the database
            token = signJWT(str(created_user.id))
            return {"user": created_user, "token": token["access_token"]}
        except Exception as e:
            logger.error(f"Error creating user: {e}")
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
    async def get_user_by_id(user_id: str) -> Optional[User]:
        try:
            user = await User.find_one({"_id": ObjectId(user_id)})
        except Exception:
            return None
        return user
    


    #update user
    @staticmethod
    async def update_user(userBody: UpdateUser, id: str) -> Optional[User]:
        try:
            user = await User.find_one({"_id": ObjectId(id)})
        except Exception:
            return None
        if not user:
            return None

        if userBody.firstname is not None:
            user.firstname = userBody.firstname
        if userBody.lastname is not None:
            user.lastname = userBody.lastname
        if userBody.username is not None:
            user.username = userBody.username
        if userBody.password is not None:
            user.password = pwd_context.hash(userBody.password)
        if userBody.Bio is not None:
            user.bio = userBody.Bio
        if userBody.image is not None:
            user.imageUrl = userBody.image
        await user.save()
        return user
    

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
            if user_id != target_user_id:
                await NotificationService.create_notification(
                    details="user " + user1.username + " started following you",
                    recipient_id=target_user_id,
                    actor_id=user_id,
                    actor_name=user1.username,
                    actor_image_url=user1.imageUrl,
                )
        await user1.save()
        await user2.save()

        return {"user1": user1, "user2": user2}


    # get the full user docs behind a user's followers/following id lists
    @staticmethod
    async def get_followers(user_id: str) -> Optional[list]:
        try:
            user = await User.find_one({"_id": ObjectId(user_id)})
        except Exception:
            return None
        if not user:
            return None
        if not user.followers:
            return []
        ids = [ObjectId(fid) for fid in user.followers]
        return await User.find({"_id": {"$in": ids}}).to_list()

    @staticmethod
    async def get_following(user_id: str) -> Optional[list]:
        try:
            user = await User.find_one({"_id": ObjectId(user_id)})
        except Exception:
            return None
        if not user:
            return None
        if not user.following:
            return []
        ids = [ObjectId(fid) for fid in user.following]
        return await User.find({"_id": {"$in": ids}}).to_list()


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


    # search users by first name, last name, or username
    @staticmethod
    async def search_users(query: str, page_str: Optional[str] = None) -> dict:
        if not query:
            return {"users": [], "currentPage": 1, "hasMore": False}

        page = int(page_str) if page_str and page_str.isdigit() else 1
        limit = 20
        skip = (page - 1) * limit

        # Match each word against any field independently, so a full-name
        # query like "husam habash" finds firstname="Husam" lastname="Habash"
        # even though neither field alone contains the whole query string.
        words = query.split()
        if not words:
            return {"users": [], "currentPage": 1, "hasMore": False}

        match_query = {"$and": [
            {"$or": [
                {"firstname": {"$regex": re.escape(word), "$options": "i"}},
                {"lastname": {"$regex": re.escape(word), "$options": "i"}},
                {"username": {"$regex": re.escape(word), "$options": "i"}},
            ]}
            for word in words
        ]}

        total = await User.find(match_query).count()
        users = await User.find(match_query).skip(skip).limit(limit).to_list()

        return {
            "users": users,
            "currentPage": page,
            "hasMore": skip + len(users) < total,
        }


    # user delete account
    @staticmethod
    async def delete_user(user_id: str):
        try:
            user = await User.find_one({"_id": ObjectId(user_id)})
        except:
            return None
        if not user:
            return None

        # TODO: this leaves a dangling id in other users followers/following
        # lists — remove user_id from everyone who references it before deleting.
        await user.delete()
        return {"message": "User deleted successfully"}