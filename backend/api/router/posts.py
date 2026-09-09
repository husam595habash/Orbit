from typing import Optional

from services.user import UserService
from services.post import PostService
from schemas.post import CreatePost, UpdatePost
from auth.auth_bearer import get_current_user_id
from exceptions import ForbiddenError, NotFoundError
from models.post import Post

from fastapi import APIRouter, Depends, status

posts_router = APIRouter()


# create post
@posts_router.post("", status_code=status.HTTP_201_CREATED)
async def create_post(
    new_post: CreatePost,
    uid: str = Depends(get_current_user_id),
    user_service: UserService = Depends(),
    post_service: PostService = Depends(),
):
    user = await user_service.get_user_by_id(uid)
    if not user:
        raise NotFoundError("User not found")

    post_in = Post(
        message=new_post.message,
        creator=uid,
        selectedFile=new_post.selectedFile,
        title=new_post.title,
    )
    created_post = await post_service.create_post(post_in)
    return created_post.model_dump(mode="json")



# get post by id, with its creator's name/imageUrl attached
@posts_router.get("/{post_id}", status_code=status.HTTP_200_OK)
async def get_post_by_id(post_id: str, post_service: PostService = Depends()):
    result = await post_service.get_post_detail(post_id)
    if not result:
        raise NotFoundError("Post not found")
    return result["post"]



# get many posts by pagination & related to user, or a specific user's posts
@posts_router.get("", status_code=status.HTTP_200_OK)
async def get_posts(
    page: Optional[str] = None,
    profileId: Optional[str] = None,
    uid: str = Depends(get_current_user_id),
    post_service: PostService = Depends(),
):
    result = await post_service.get_all_posts(page, uid, profileId)
    return {
        "posts": result["posts"],
        "currentPage": result["currentPage"],
        "numberOfPages": result["numberOfPages"],
        "total": result["total"],
    }



# update post
@posts_router.patch("/{post_id}", status_code=status.HTTP_200_OK)
async def update_post(
    post_id: str,
    new_post: UpdatePost,
    uid: str = Depends(get_current_user_id),
    post_service: PostService = Depends()
):
    existing_post = await post_service.get_post_by_id(post_id)
    if not existing_post:
        raise NotFoundError("Post not found")
    if existing_post.creator != uid:
        raise ForbiddenError("You are not authorized to update this post")

    result = await post_service.update_post(post_id, new_post)
    return result["data"].model_dump(mode="json")


# like a post
@posts_router.patch("/{post_id}/like", status_code=status.HTTP_200_OK)
async def like(
    post_id: str,
    uid: str = Depends(get_current_user_id),
    post_service: PostService = Depends(),
):
    result = await post_service.like_post(post_id, uid)
    if not result:
        raise NotFoundError("Post not found")
    return result["data"].model_dump(mode="json")



# delete post
@posts_router.delete("/{post_id}", status_code=status.HTTP_200_OK)
async def delete_post(
    post_id: str,
    uid: str = Depends(get_current_user_id),
    post_service: PostService = Depends(),
):
    existing_post = await post_service.get_post_by_id(post_id)
    if not existing_post:
        raise NotFoundError("Post not found")
    if uid != existing_post.creator:
        raise ForbiddenError("You are not authorized to delete this post")

    return await post_service.delete_post(post_id)
