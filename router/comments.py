from typing import Optional

from fastapi import APIRouter, status, Depends
from fastapi.responses import JSONResponse

from auth.auth_bearer import JWTBearer
from auth.auth_handler import decodeJWT
from services.comment import CommentService
from interface.posts import CreateComment

comments_router = APIRouter()


# create a comment on a post
@comments_router.post("/{post_id}", status_code=status.HTTP_201_CREATED)
async def create_comment(
    post_id: str,
    data: CreateComment,
    token: str = Depends(JWTBearer()),
    comment_service: CommentService = Depends(),
):
    user_id = decodeJWT(token)["user_id"]
    result = await comment_service.create_comment(data, post_id, user_id)
    if not result:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "Failed to add comment"}
        )
    return result.model_dump(mode="json")


# get comments for a post, paginated
@comments_router.get("/{post_id}", status_code=status.HTTP_200_OK)
async def get_comments(
    post_id: str,
    page: Optional[str] = None,
    comment_service: CommentService = Depends(),
):
    result = await comment_service.get_post_comments(post_id, page)
    if result is None:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "Failed to get comments"}
        )
    return result


# delete a comment (only the comment's own author can delete it)
@comments_router.delete("/{comment_id}", status_code=status.HTTP_200_OK)
async def delete_comment(
    comment_id: str,
    token: str = Depends(JWTBearer()),
    comment_service: CommentService = Depends(),
):
    user_id = decodeJWT(token)["user_id"]
    existing_comment = await comment_service.get_comment_by_id(comment_id)
    if not existing_comment:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"message": "Comment not found"}
        )
    if existing_comment.user_id != user_id:
        return JSONResponse(
            status_code=status.HTTP_403_FORBIDDEN,
            content={"message": "You are not authorized to delete this comment"}
        )

    result = await comment_service.delete_comment(comment_id)
    if not result:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"message": "Failed to delete comment"}
        )
    return result
