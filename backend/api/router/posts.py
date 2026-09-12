from typing import Optional

from di import get_post_service
from services.post import PostService
from schemas.post import CreatePost, UpdatePost
from auth.auth_bearer import get_current_user_id
from exceptions import ForbiddenError
from models.post import Post

from fastapi import APIRouter, Depends, status

posts_router = APIRouter()


# create post
@posts_router.post("", status_code=status.HTTP_201_CREATED)
async def create_post(
    new_post: CreatePost,
    uid: str = Depends(get_current_user_id),
    post_service: PostService = Depends(get_post_service),
):
    post_in = Post(
        message=new_post.message,
        creator=uid,
        selectedFile=new_post.selectedFile,
        title=new_post.title,
    )
    return await post_service.create_post(post_in)



# get post by id, with its creator's name/imageUrl attached
@posts_router.get("/{post_id}", status_code=status.HTTP_200_OK)
async def get_post_by_id(post_id: str, post_service: PostService = Depends(get_post_service)):
    return await post_service.get_post_detail(post_id)




# get many posts by pagination & related to user, or a specific user's posts
@posts_router.get("", status_code=status.HTTP_200_OK)
async def get_posts(
    page: Optional[str] = None,
    profileId: Optional[str] = None,
    uid: str = Depends(get_current_user_id),
    post_service: PostService = Depends(get_post_service),
):
    return await post_service.get_all_posts(page, uid, profileId)



# update post
@posts_router.patch("/{post_id}", status_code=status.HTTP_200_OK)
async def update_post(
    post_id: str,
    new_post: UpdatePost,
    uid: str = Depends(get_current_user_id),
    post_service: PostService = Depends(get_post_service)
):
    existing_post = await post_service.get_post_by_id(post_id)
    if existing_post.creator != uid:
        raise ForbiddenError("You are not authorized to update this post")

    return await post_service.update_post(post_id, new_post)


# like a post
@posts_router.patch("/{post_id}/like", status_code=status.HTTP_200_OK)
async def like(
    post_id: str,
    uid: str = Depends(get_current_user_id),
    post_service: PostService = Depends(get_post_service),
):
    return await post_service.like_post(post_id, uid)



# delete post
@posts_router.delete("/{post_id}", status_code=status.HTTP_200_OK)
async def delete_post(
    post_id: str,
    uid: str = Depends(get_current_user_id),
    post_service: PostService = Depends(get_post_service),
):
    existing_post = await post_service.get_post_by_id(post_id)
    if uid != existing_post.creator:
        raise ForbiddenError("You are not authorized to delete this post")

    return await post_service.delete_post(post_id)
