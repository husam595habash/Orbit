import math
from typing import Optional

from bson import ObjectId
from fastapi import Depends

from models.comment import Comment
from models.post import Post
from models.user import User
from schemas.post import CreateComment
from services.notification import NotificationService


class CommentService:

    def __init__(self, notification_service: NotificationService = Depends()):
        self.notification_service = notification_service

    async def create_comment(self, data: CreateComment, post_id: str, user_id: str):
        try:
            post = await Post.find_one({"_id": ObjectId(post_id)})
        except Exception:
            return None
        if not post:
            return None

        new_comment = Comment(
            post_id=post_id,
            user_id=user_id,
            value=data.value,
        )
        await new_comment.save()

        commenter = await User.find_one({"_id": ObjectId(user_id)})
        if commenter and post.creator != user_id:
            details = "user " + commenter.username + " commented on your post"
            await self.notification_service.create_notification(
                details=details,
                recipient_id=post.creator,
                actor_id=user_id,
                actor_name=commenter.username,
                actor_image_url=commenter.imageUrl,
            )

        return new_comment

    async def get_post_comments(self, post_id: str, page_str: Optional[str] = None):
        page = int(page_str) if page_str and page_str.isdigit() else 1
        limit = 10
        skip = (page - 1) * limit

        total = await Comment.find({"post_id": post_id}).count()
        comments = await Comment.find({"post_id": post_id}) \
            .sort(-Comment.id).skip(skip).limit(limit).to_list()

        author_ids = {ObjectId(c.user_id) for c in comments}
        authors = await User.find({"_id": {"$in": list(author_ids)}}).to_list()
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
        try:
            comment = await Comment.find_one({"_id": ObjectId(comment_id)})
        except Exception:
            return None
        return comment

    async def delete_comment(self, comment_id: str):
        try:
            comment = await Comment.find_one({"_id": ObjectId(comment_id)})
        except Exception:
            return None
        if not comment:
            return None
        await comment.delete()
        return {"message": "Comment deleted successfully"}
