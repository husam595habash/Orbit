from typing import Optional

from services.user import UserService
from services.post import PostService
from interface.posts import CreatePost, UpdatePost
from auth.auth_bearer import JWTBearer
from auth.auth_handler import decodeJWT
from models.posts import Post

from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse

posts_router = APIRouter()


# create post
@posts_router.post("", status_code=status.HTTP_201_CREATED)
async def create_post(
    new_post: CreatePost,
    token: str = Depends(JWTBearer()),
    user_service: UserService = Depends(),
    post_service: PostService = Depends(),
):
    uid = decodeJWT(token)["user_id"]
    user = await user_service.get_user_by_id(uid)
    if not user:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"message": "User not found"}
        )

    post_in = Post(
        message=new_post.message,
        creator=uid,
        selectedFile=new_post.selectedFile,
        title=new_post.title,
    )
    created_post = await post_service.create_post(post_in)
    if not created_post:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "Failed to create post"}
        )
    return created_post.model_dump(mode="json")



# get post by id, with its creator's name/imageUrl attached
@posts_router.get("/{post_id}", status_code=status.HTTP_200_OK)
async def get_post_by_id(post_id: str, post_service: PostService = Depends()):
    result = await post_service.get_post_detail(post_id)
    if not result:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"message": "Post not found"}
        )
    return result["post"]



# get many posts by pagination & related to user
@posts_router.get("", status_code=status.HTTP_200_OK)
async def get_posts(
    page: Optional[str] = None,
    token: str = Depends(JWTBearer()),
    post_service: PostService = Depends(),
):
    uid = decodeJWT(token)["user_id"]
    result = await post_service.get_all_posts(page, uid)
    if not result:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "Failed to get posts"}
        )
    return {
        "posts": result["posts"],
        "currentPage": result["currentPage"],
        "numberOfPages": result["numberOfPages"],
    }



# update post
@posts_router.patch("/{post_id}", status_code=status.HTTP_200_OK)
async def update_post(
    post_id: str,
    new_post: UpdatePost,
    token: str = Depends(JWTBearer()),
    post_service: PostService = Depends()
):
    uid = decodeJWT(token)["user_id"]
    existing_post = await post_service.get_post_by_id(post_id)
    if not existing_post:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"message": "Post not found"}
        )
    if existing_post.creator != uid:
        return JSONResponse(
            status_code=status.HTTP_403_FORBIDDEN,
            content={"message": "You are not authorized to update this post"}
        )

    result = await post_service.update_post(post_id, new_post)
    if not result:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "Failed to update post"}
        )
    return result["data"].model_dump(mode="json")


# like a post
@posts_router.patch("/{post_id}/like", status_code=status.HTTP_200_OK)
async def like(
    post_id: str,
    token: str = Depends(JWTBearer()),
    post_service: PostService = Depends(),
):
    uid = decodeJWT(token)["user_id"]
    result = await post_service.like_post(post_id, uid)
    if not result:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"message": "Post not found"}
        )
    return result["data"].model_dump(mode="json")



# delete post
@posts_router.delete("/{post_id}", status_code=status.HTTP_200_OK)
async def delete_post(
    post_id: str,
    token: str = Depends(JWTBearer()),
    post_service: PostService = Depends(),
):
    uid = decodeJWT(token)["user_id"]
    existing_post = await post_service.get_post_by_id(post_id)
    if not existing_post:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"message": "Post not found"}
        )
    if uid != existing_post.creator:
        return JSONResponse(
            status_code=status.HTTP_403_FORBIDDEN,
            content={"message": "You are not authorized to delete this post"}
        )

    result = await post_service.delete_post(post_id)
    if not result:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "Failed to delete post"}
        )
    return result