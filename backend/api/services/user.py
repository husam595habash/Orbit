import re
from typing import Optional

from bson import ObjectId
from fastapi import Depends
from passlib.context import CryptContext

from auth.auth_handler import signJWT
from exceptions import UnauthorizedError
from models.user import User
from schemas.user import CreateUser, LoginUser, UpdateUser
from services.notification import NotificationService

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class UserService:

    def __init__(self, notification_service: NotificationService = Depends()):
        self.notification_service = notification_service

    async def create_user(self, user: CreateUser):
        user_in = User(
            firstname=user.firstname,
            lastname=user.lastname,
            username=user.username,
            email=user.email,
            password=pwd_context.hash(user.password)
        )

        created_user = await user_in.save()
        token = signJWT(str(created_user.id))
        return {"user": created_user, "token": token["access_token"]}


    # get user by email
    async def get_user_by_email(self, email: str) -> Optional[User]:
        user = await User.find_one(User.email == email)
        return user

    # login user
    async def authenticate_user(self, userBody: LoginUser) -> dict:
        user = await self.get_user_by_email(email=userBody.email)
        if not user or not pwd_context.verify(userBody.password, user.password):
            raise UnauthorizedError("Invalid email or password")

        token = signJWT(str(user.id))
        return {"user": user, "token": token["access_token"]}

    async def get_user_by_id(self, user_id: str) -> Optional[User]:
        try:
            user = await User.find_one({"_id": ObjectId(user_id)})
        except Exception:
            return None
        return user


    # update user
    async def update_user(self, userBody: UpdateUser, id: str) -> Optional[User]:
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
    async def follow_user(self, user_id: str, target_user_id: str) -> Optional[dict]:
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
                await self.notification_service.create_notification(
                    details="user " + user1.username + " started following you",
                    recipient_id=target_user_id,
                    actor_id=user_id,
                    actor_name=user1.username,
                    actor_image_url=user1.imageUrl,
                )
        await user1.save()
        await user2.save()

        return {"user1": user1, "user2": user2}


    # get the full user docs behind a user's followers/following id lists,
    # a page at a time instead of the whole (potentially huge) list at once
    async def _get_user_list(self, user_id: str, list_field: str, page_str: Optional[str] = None) -> Optional[dict]:
        try:
            user = await User.find_one({"_id": ObjectId(user_id)})
        except Exception:
            return None
        if not user:
            return None

        all_ids = getattr(user, list_field)
        if not all_ids:
            return {"users": [], "currentPage": 1, "hasMore": False}

        page = int(page_str) if page_str and page_str.isdigit() else 1
        limit = 20
        skip = (page - 1) * limit

        page_ids = [ObjectId(fid) for fid in all_ids[skip:skip + limit]]
        users = await User.find({"_id": {"$in": page_ids}}).to_list() if page_ids else []

        return {
            "users": users,
            "currentPage": page,
            "hasMore": skip + len(page_ids) < len(all_ids),
        }

    async def get_followers(self, user_id: str, page_str: Optional[str] = None) -> Optional[dict]:
        return await self._get_user_list(user_id, "followers", page_str)

    async def get_following(self, user_id: str, page_str: Optional[str] = None) -> Optional[dict]:
        return await self._get_user_list(user_id, "following", page_str)


    # get some suggested users to follow
    async def get_suggested_users(self, user_id: str, limit: int = 10) -> Optional[dict]:
        try:
            main_user = await User.find_one({"_id": ObjectId(user_id)})
        except Exception:
            return None
        if not main_user:
            return None

        # don't suggest yourself or people you already follow
        exclude_ids = {str(main_user.id), *main_user.following}

        if not main_user.following:
            return {"users": []}

        # one batched lookup for everyone the main user follows, instead of
        # a query per followed user
        followed_object_ids = [ObjectId(fid) for fid in main_user.following]
        followed_users = await User.find({"_id": {"$in": followed_object_ids}}).to_list()

        related_ids = set()
        for followed_user in followed_users:
            for related_id in followed_user.followers + followed_user.following:
                if related_id not in exclude_ids:
                    exclude_ids.add(related_id)
                    related_ids.add(related_id)

        if not related_ids:
            return {"users": []}

        # one batched lookup for all candidate suggestions, instead of a
        # query per candidate, capped so the response can't grow unbounded
        related_object_ids = [ObjectId(rid) for rid in related_ids]
        suggestions = await User.find({"_id": {"$in": related_object_ids}}).limit(limit).to_list()

        return {"users": suggestions}


    # search users by first name, last name, or username
    async def search_users(self, query: str, page_str: Optional[str] = None) -> dict:
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
    async def delete_user(self, user_id: str):
        try:
            user = await User.find_one({"_id": ObjectId(user_id)})
        except Exception:
            return None
        if not user:
            return None

        # TODO: this leaves a dangling id in other users followers/following
        # lists — remove user_id from everyone who references it before deleting.
        await user.delete()
        return {"message": "User deleted successfully"}
