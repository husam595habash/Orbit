import math
from typing import Optional
from bson import ObjectId
from models.post import Post
from models.user import User
import logging
from schemas.post import UpdatePost
from services.notification import NotificationService
from services.comment import CommentService


logger = logging.getLogger(__name__)


class PostService:
    @staticmethod
    async def create_post(post: Post):
        try:
            await post.save()
            return post
        except:
            logger.exception("Failed to create post")
            return None


    # get post by id
    @staticmethod
    async def get_post_by_id(post_id: str):
        try:
            post = await Post.find_one({"_id": ObjectId(post_id)})
        except:
            return None
        return post


    # build a JSON-ready post, with its creator's name/imageUrl attached
    @staticmethod
    async def _post_to_dict(post: Post) -> dict:
        post_data = post.model_dump(mode="json")

        creator = await User.find_one({"_id": ObjectId(post.creator)})
        if creator:
            post_data["name"] = creator.username
            post_data["creatorImageUrl"] = creator.imageUrl

        return post_data

    # get post by id, with its creator's name/imageUrl and first page of comments attached
    # (call CommentService.get_post_comments directly to page past the first 10)
    @staticmethod
    async def get_post_detail(post_id: str):
        try:
            post = await Post.find_one({"_id": ObjectId(post_id)})
        except:
            return None
        if not post:
            return None

        post_data = await PostService._post_to_dict(post)

        comments_result = await CommentService.get_post_comments(str(post.id), "1")
        post_data["comments"] = comments_result["comments"] if comments_result else []

        return {"post": post_data}


    # get all posts from users the given user follows (plus their own), or a specific user's posts
    @staticmethod
    async def get_all_posts(page_str: Optional[str], user_id: Optional[str], profile_id: Optional[str] = None):
        try:
            page = int(page_str) if page_str and page_str.isdigit() else 1

            limit = 6
            skip = (page - 1) * limit

            match_query = {}
            if profile_id:
                match_query = {"creator": profile_id}
            elif user_id:
                main_user = await User.find_one({"_id": ObjectId(user_id)})
                if main_user:
                    following_ids = main_user.following + [str(main_user.id)]
                    match_query = {"creator": {"$in": following_ids}}
            else:
                return {"posts": [], "currentPage": page, "numberOfPages": 0}

            total = await Post.find(match_query).count()
            posts = await Post.find(match_query) \
                .sort(-Post.createdAt).skip(skip).limit(limit).to_list()

            data = [await PostService._post_to_dict(post) for post in posts]

            return {
                "posts": data,
                "currentPage": page,
                "numberOfPages": math.ceil(total / limit) if total else 0
            }

        except Exception as e:
            logger.error(f"Error in get_all_posts: {e}")
            return None



    @staticmethod
    async def update_post(post_id: str, new_post: UpdatePost):
        try:
            post = await Post.find_one({"_id": ObjectId(post_id)})
            if not post:
                return None

            if new_post.title is not None:
                post.title = new_post.title
            if new_post.message is not None:
                post.message = new_post.message
            if new_post.selectedFile is not None:
                post.selectedFile = new_post.selectedFile

            await post.save()
            return {"data": post}
        except:
            logger.exception("Failed to update post")
            return None


    @staticmethod
    async def like_post(post_id: str, user_id: str):
        try:
            post = await Post.find_one({"_id": ObjectId(post_id)})
            if not post:
                return None
            if user_id in post.likes:
                post.likes.remove(user_id)
            else:
                post.likes.append(user_id)
                if post.creator != user_id:
                    liker = await User.find_one({"_id": ObjectId(user_id)})
                    await NotificationService.create_notification(
                        details="user " + liker.username + " liked your post",
                        recipient_id=post.creator,
                        actor_id=user_id,
                        actor_name=liker.username,
                        actor_image_url=liker.imageUrl,
                    )
            await post.save()
            return {"data": post}
        except Exception as e:
            logger.error(e)
            return None


    # delete post
    @staticmethod
    async def delete_post(post_id: str):
        try:
            post = await Post.find_one({"_id": ObjectId(post_id)})
            if not post:
                return {"message": "Post not found"}
            await post.delete()
            return {"message": "Post deleted successfully"}
        except Exception as e:
            logger.error(e)
            return None
        

            
        
        