import math
from typing import Optional

from exceptions import NotFoundError
from models.post import Post
from schemas.post import UpdatePost
from repositories.post_repository import PostRepository
from repositories.user_repository import UserRepository
from services.notification import NotificationService
from services.comment import CommentService


class PostService:

    def __init__(
        self,
        post_repository: PostRepository,
        user_repository: UserRepository,
        notification_service: NotificationService,
        comment_service: CommentService,
    ):
        self.post_repository = post_repository
        self.user_repository = user_repository
        self.notification_service = notification_service
        self.comment_service = comment_service

    async def create_post(self, post: Post):
        creator = await self.user_repository.find_by_id(post.creator)
        if not creator:
            raise NotFoundError("User not found")
        await self.post_repository.save(post)
        return post.model_dump(mode="json")


    # get post by id
    async def get_post_by_id(self, post_id: str):
        post = await self.post_repository.find_by_id(post_id)
        if not post:
            raise NotFoundError("Post not found")
        return post


    # build a JSON-ready post, with its creator's name/imageUrl attached
    async def _post_to_dict(self, post: Post) -> dict:
        post_data = post.model_dump(mode="json")

        creator = await self.user_repository.find_by_id(post.creator)
        if creator:
            full_name = f"{creator.firstname} {creator.lastname}".strip()
            post_data["name"] = full_name or creator.username
            post_data["username"] = creator.username
            post_data["creatorImageUrl"] = creator.imageUrl

        return post_data

    # build JSON-ready posts for a whole page at once, fetching all their
    # creators in a single batched query instead of one query per post.
    async def _posts_to_dicts(self, posts: list[Post]) -> list[dict]:
        creator_ids = list({p.creator for p in posts})
        creators = await self.user_repository.find_by_ids(creator_ids)
        creators_by_id = {str(creator.id): creator for creator in creators}

        results = []
        for post in posts:
            post_data = post.model_dump(mode="json")
            creator = creators_by_id.get(post.creator)
            if creator:
                full_name = f"{creator.firstname} {creator.lastname}".strip()
                post_data["name"] = full_name or creator.username
                post_data["username"] = creator.username
                post_data["creatorImageUrl"] = creator.imageUrl
            results.append(post_data)

        return results

    # get post by id, with its creator's name/imageUrl and first page of comments attached
    # (call CommentService.get_post_comments directly to page past the first 10)
    async def get_post_detail(self, post_id: str):
        post = await self.get_post_by_id(post_id)

        post_data = await self._post_to_dict(post)

        comments_result = await self.comment_service.get_post_comments(str(post.id), "1")
        post_data["comments"] = comments_result["comments"] if comments_result else []

        return {"post": post_data}


    # get all posts from users the given user follows (plus their own), or a specific user's posts
    async def get_all_posts(self, page_str: Optional[str], user_id: Optional[str], profile_id: Optional[str] = None):
        page = int(page_str) if page_str and page_str.isdigit() else 1

        limit = 6
        skip = (page - 1) * limit

        match_query = {}
        if profile_id:
            match_query = {"creator": profile_id}
        elif user_id:
            main_user = await self.user_repository.find_by_id(user_id)
            if main_user:
                following_ids = main_user.following + [str(main_user.id)]
                match_query = {"creator": {"$in": following_ids}}
        else:
            return {"posts": [], "currentPage": page, "numberOfPages": 0, "total": 0}

        posts, total = await self.post_repository.find_posts_page(match_query, skip=skip, limit=limit)

        data = await self._posts_to_dicts(posts)

        return {
            "posts": data,
            "currentPage": page,
            "numberOfPages": math.ceil(total / limit) if total else 0,
            "total": total,
        }


    async def update_post(self, post_id: str, new_post: UpdatePost):
        post = await self.get_post_by_id(post_id)

        if new_post.title is not None:
            post.title = new_post.title
        if new_post.message is not None:
            post.message = new_post.message
        if new_post.selectedFile is not None:
            post.selectedFile = new_post.selectedFile

        await self.post_repository.save(post)
        return post.model_dump(mode="json")


    async def like_post(self, post_id: str, user_id: str):
        post = await self.get_post_by_id(post_id)
        if user_id in post.likes:
            post.likes.remove(user_id)
        else:
            post.likes.append(user_id)
            if post.creator != user_id:
                liker = await self.user_repository.find_by_id(user_id)
                await self.notification_service.create_notification(
                    details="user " + liker.username + " liked your post",
                    recipient_id=post.creator,
                    actor_id=user_id,
                    actor_name=liker.username,
                    actor_image_url=liker.imageUrl,
                )
        await self.post_repository.save(post)
        return post.model_dump(mode="json")


    # delete post
    async def delete_post(self, post_id: str):
        post = await self.get_post_by_id(post_id)
        await self.post_repository.delete(post)
        return {"message": "Post deleted successfully"}
