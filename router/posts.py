from services.user import UserService
from services.post import PostService
from interface.posts import CreatePost
from auth.auth_bearer import JWTBearer
from auth.auth_handler import decodeJWT
from models.posts import Post

from fastapi import APIRouter, Depends, HTTPException, status

posts_router = APIRouter()


# create post
@posts_router.post('/', status_code=status.HTTP_201_CREATED)
async def create_post(
    new_post: CreatePost,
    token: str = Depends(JWTBearer()),
    user_service: UserService = Depends(),
    post_service: PostService = Depends(),
):
    try:
        uid = decodeJWT(token)["user_id"]
        user = await user_service.get_user_by_id(uid)
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

        post_in = Post(
            message=new_post.message,
            creator=uid,
            selectedFile=new_post.selectedFile,
            title=new_post.title,
        )
        created_post = await post_service.create_post(post_in)
        if not created_post:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Failed to create post")
        return {"post": created_post}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))
    



