from typing import Optional

from fastapi import APIRouter, status, Depends

from auth.auth_bearer import get_current_user_id
from exceptions import NotFoundError, ForbiddenError
from services.comment import CommentService
from schemas.post import CreateComment

comments_router = APIRouter()


# create a comment on a post
@comments_router.post("/{post_id}", status_code=status.HTTP_201_CREATED)
async def create_comment(
    post_id: str,
    data: CreateComment,
    user_id: str = Depends(get_current_user_id),
    comment_service: CommentService = Depends(),
):
    result = await comment_service.create_comment(data, post_id, user_id)
    if not result:
        raise NotFoundError("Post not found")
    return result.model_dump(mode="json")


# get comments for a post, paginated
@comments_router.get("/{post_id}", status_code=status.HTTP_200_OK)
async def get_comments(
    post_id: str,
    page: Optional[str] = None,
    comment_service: CommentService = Depends(),
):
    return await comment_service.get_post_comments(post_id, page)


# delete a comment (only the comment's own author can delete it)
@comments_router.delete("/{comment_id}", status_code=status.HTTP_200_OK)
async def delete_comment(
    comment_id: str,
    user_id: str = Depends(get_current_user_id),
    comment_service: CommentService = Depends(),
):
    existing_comment = await comment_service.get_comment_by_id(comment_id)
    if not existing_comment:
        raise NotFoundError("Comment not found")
    if existing_comment.user_id != user_id:
        raise ForbiddenError("You are not authorized to delete this comment")

    return await comment_service.delete_comment(comment_id)
