import logging
import math
from typing import Optional

from bson import ObjectId
from models.comment import Comment
from models.posts import Post
from models.users import User
from interface.posts import CreateComment
from services.notification import NotificationService

logger = logging.getLogger(__name__)


class CommentService:
    @staticmethod
    async def create_comment(data: CreateComment, post_id: str, user_id: str):
        try:
            post = await Post.find_one({"_id": ObjectId(post_id)})
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
                await NotificationService.create_notification(
                    details=details,
                    recipient_id=post.creator,
                    actor_id=user_id,
                    actor_name=commenter.username,
                    actor_image_url=commenter.imageUrl,
                )
   
            
            return new_comment
        except Exception as e:
            logger.error(e)
            return None

    @staticmethod
    async def get_post_comments(post_id: str, page_str: Optional[str] = None):
        try:
            page = int(page_str) if page_str and page_str.isdigit() else 1
            limit = 10
            skip = (page - 1) * limit

            total = await Comment.find({"post_id": post_id}).count()
            comments = await Comment.find({"post_id": post_id}) \
                .sort(-Comment.id).skip(skip).limit(limit).to_list()

            comment_list = []
            for c in comments:
                comment_data = c.model_dump(mode="json")
                author = await User.find_one({"_id": ObjectId(c.user_id)})
                if author:
                    comment_data["user"] = {"name": author.username, "imageUrl": author.imageUrl}
                comment_list.append(comment_data)

            return {
                "comments": comment_list,
                "currentPage": page,
                "numberOfPages": math.ceil(total / limit) if total else 0
            }
        except Exception as e:
            logger.error(e)
            return None

    # get a single comment by id (used for ownership checks before deleting)
    @staticmethod
    async def get_comment_by_id(comment_id: str):
        try:
            comment = await Comment.find_one({"_id": ObjectId(comment_id)})
        except:
            return None
        return comment

    @staticmethod
    async def delete_comment(comment_id: str):
        try:
            comment = await Comment.find_one({"_id": ObjectId(comment_id)})
            if not comment:
                return {"message": "Comment not found"}
            await comment.delete()
            return {"message": "Comment deleted successfully"}
        except Exception as e:
            logger.error(e)
            return None
