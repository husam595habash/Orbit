from typing import Optional

from passlib.context import CryptContext

from auth.auth_handler import signJWT, verify_google_token
from exceptions import NotFoundError, UnauthorizedError
from models.user import User
from schemas.user import CreateUser, LoginUser, UpdateUser
from repositories.user_repository import UserRepository
from services.notification import NotificationService

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def _to_public_dict(user: User) -> dict:
    return user.model_dump(mode="json", exclude={"password"})


class UserService:

    def __init__(
        self,
        user_repository: UserRepository,
        notification_service: NotificationService,
    ):
        self.user_repository = user_repository
        self.notification_service = notification_service

    async def create_user(self, user: CreateUser):
        user_in = User(
            firstname=user.firstname,
            lastname=user.lastname,
            username=user.username,
            email=user.email,
            password=pwd_context.hash(user.password)
        )

        created_user = await self.user_repository.save(user_in)
        token = signJWT(str(created_user.id))
        return {"user": _to_public_dict(created_user), "token": token["access_token"]}


    # login user
    async def authenticate_user(self, userBody: LoginUser) -> dict:
        user = await self.user_repository.find_by_email(userBody.email)
        if not user or not user.password or not pwd_context.verify(userBody.password, user.password):
            raise UnauthorizedError("Invalid email or password")

        token = signJWT(str(user.id))
        return {"user": _to_public_dict(user), "token": token["access_token"]}



    async def authenticate_google_user(self, id_token: str) -> dict:
        google_user = verify_google_token(id_token)

        user = await self.user_repository.find_by_email(google_user["email"])
        if not user:
            user_in = User(
                firstname=google_user["firstname"],
                lastname=google_user["lastname"],
                username=google_user["username"],
                email=google_user["email"],
                imageUrl=google_user["imageUrl"],
            )
            user = await self.user_repository.save(user_in)

        token = signJWT(str(user.id))
        return {"user": _to_public_dict(user), "token": token["access_token"]}

    async def get_user_by_id(self, user_id: str) -> User:
        user = await self.user_repository.find_by_id(user_id)
        if not user:
            raise NotFoundError("User not found")
        return user

    async def get_user_profile(self, user_id: str) -> dict:
        return _to_public_dict(await self.get_user_by_id(user_id))


    # update user
    async def update_user(self, userBody: UpdateUser, id: str) -> dict:
        user = await self.get_user_by_id(id)

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
        await self.user_repository.save(user)
        return _to_public_dict(user)


    # follow user
    async def follow_user(self, user_id: str, target_user_id: str) -> dict:
        user1 = await self.get_user_by_id(user_id)
        user2 = await self.get_user_by_id(target_user_id)

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
        await self.user_repository.save(user1)
        await self.user_repository.save(user2)

        return {"user1": _to_public_dict(user1), "user2": _to_public_dict(user2)}


    # get the full user docs behind a user's followers/following id lists,
    # a page at a time instead of the whole (potentially huge) list at once
    async def _get_user_list(self, user_id: str, list_field: str, page_str: Optional[str] = None) -> dict:
        user = await self.get_user_by_id(user_id)

        all_ids = getattr(user, list_field)
        if not all_ids:
            return {"users": [], "currentPage": 1, "hasMore": False}

        page = int(page_str) if page_str and page_str.isdigit() else 1
        limit = 20
        skip = (page - 1) * limit

        page_ids = all_ids[skip:skip + limit]
        users = await self.user_repository.find_by_ids(page_ids)

        return {
            "users": [_to_public_dict(u) for u in users],
            "currentPage": page,
            "hasMore": skip + len(page_ids) < len(all_ids),
        }

    async def get_followers(self, user_id: str, page_str: Optional[str] = None) -> dict:
        return await self._get_user_list(user_id, "followers", page_str)

    async def get_following(self, user_id: str, page_str: Optional[str] = None) -> dict:
        return await self._get_user_list(user_id, "following", page_str)


    # get some suggested users to follow
    async def get_suggested_users(self, user_id: str, limit: int = 10) -> dict:
        main_user = await self.get_user_by_id(user_id)

        # don't suggest yourself or people you already follow
        exclude_ids = {str(main_user.id), *main_user.following}

        if not main_user.following:
            return {"users": []}

        # one batched lookup for everyone the main user follows, instead of
        # a query per followed user
        followed_users = await self.user_repository.find_by_ids(main_user.following)

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
        suggestions = await self.user_repository.find_by_ids(list(related_ids), limit=limit)

        return {"users": [_to_public_dict(u) for u in suggestions]}


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

        users, total = await self.user_repository.search(words, skip=skip, limit=limit)

        return {
            "users": [_to_public_dict(u) for u in users],
            "currentPage": page,
            "hasMore": skip + len(users) < total,
        }


    # user delete account
    async def delete_user(self, user_id: str):
        user = await self.get_user_by_id(user_id)

        # TODO: this leaves a dangling id in other users followers/following
        # lists — remove user_id from everyone who references it before deleting.
        await self.user_repository.delete(user)
        return {"message": "User deleted successfully"}
