import math
from typing import Optional

from exceptions import NotFoundError
from models.comment import Comment
from schemas.post import CreateComment
from repositories.comment_repository import CommentRepository
from repositories.post_repository import PostRepository
from repositories.user_repository import UserRepository
from services.notification import NotificationService


class CommentService:

    def __init__(
        self,
        comment_repository: CommentRepository,
        post_repository: PostRepository,
        user_repository: UserRepository,
        notification_service: NotificationService,
    ):
        self.comment_repository = comment_repository
        self.post_repository = post_repository
        self.user_repository = user_repository
        self.notification_service = notification_service

    async def create_comment(self, data: CreateComment, post_id: str, user_id: str):
        post = await self.post_repository.find_by_id(post_id)
        if not post:
            raise NotFoundError("Post not found")

        new_comment = Comment(
            post_id=post_id,
            user_id=user_id,
            value=data.value,
        )
        await self.comment_repository.save(new_comment)

        commenter = await self.user_repository.find_by_id(user_id)
        if commenter and post.creator != user_id:
            details = "user " + commenter.username + " commented on your post"
            await self.notification_service.create_notification(
                details=details,
                recipient_id=post.creator,
                actor_id=user_id,
                actor_name=commenter.username,
                actor_image_url=commenter.imageUrl,
            )

        return new_comment.model_dump(mode="json")

    async def get_post_comments(self, post_id: str, page_str: Optional[str] = None):
        page = int(page_str) if page_str and page_str.isdigit() else 1
        limit = 10
        skip = (page - 1) * limit

        comments, total = await self.comment_repository.find_page_by_post(post_id, skip=skip, limit=limit)

        author_ids = list({c.user_id for c in comments})
        authors = await self.user_repository.find_by_ids(author_ids)
        authors_by_id = {str(author.id): author for author in authors}

        comment_list = []
        for c in comments:
            comment_data = c.model_dump(mode="json")
            author = authors_by_id.get(c.user_id)
            if author:
                comment_data["user"] = {"name": author.username, "imageUrl": author.imageUrl}
            comment_list.append(comment_data)

        return {
            "comments": comment_list,
            "currentPage": page,
            "numberOfPages": math.ceil(total / limit) if total else 0
        }

    # get a single comment by id (used for ownership checks before deleting)
    async def get_comment_by_id(self, comment_id: str):
        comment = await self.comment_repository.find_by_id(comment_id)
        if not comment:
            raise NotFoundError("Comment not found")
        return comment

    async def delete_comment(self, comment_id: str):
        comment = await self.get_comment_by_id(comment_id)
        await self.comment_repository.delete(comment)
        return {"message": "Comment deleted successfully"}
