import math
from typing import Any, Dict, List, Mapping
from bson import ObjectId, Regex
from models.posts import Post
from models.users import User
import logging
from interface.posts import UpdatePost, CreateComment


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


    # add comment to post
    @staticmethod
    async def add_comment(comment: CreateComment, post_id: str, user_id: str):
        try:
            post = await Post.find_one({"_id": ObjectId(post_id)})
        except:
            return None
        if not post:
            return None

        post.comments.append(comment.value)
        await post.save()

        # commenter = await User.find_one({"_id": ObjectId(user_id)})
        # TODO: calling notification
        return {"data": post}


    # get post by id
    @staticmethod
    async def get_post_by_id(post_id: str):
        try:
            post = await Post.find_one({"_id": ObjectId(post_id)})
        except:
            return None
        return post


    # search posts and users matching a text query
    @staticmethod
    async def search_posts_and_users(query: str):
        try:
            posts = await Post.find_many({"$text": {"$search": query}}).to_list()
            users = await User.find_many({"$text": {"$search": query}}).to_list()
        except:
            return None
        return {"users": users, "posts": posts}


    # get all posts from users the given user follows (plus their own)
    @staticmethod
    async def get_all_posts(page_str: str, user_id: str):
        try:
            page = 1
            if page_str:
                page = int(page_str)
            if page < 1:
                return None

            limit = 2
            start_index = (page - 1) * limit

            main_user = await User.find_one({"_id": ObjectId(user_id)})
            if not main_user:
                return None
            main_user.following.append(str(main_user.id))

            creator_filters = [{"creator": uid} for uid in main_user.following]

            total = await Post.find({"$or": creator_filters}).count()
            posts = await Post.find({"$or": creator_filters}) \
                .sort(-Post.createdAt).limit(limit).skip(start_index).to_list()

            return {"data": posts, "currentPage": page, "numberOfPages": math.ceil(total / limit)}
        except:
            logger.exception("Failed to get all posts")
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
                # TODO: calling notification
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
        

            
        
        