from models.comment import Comment
from repositories.base import BaseRepository


class CommentRepository(BaseRepository[Comment]):
    model = Comment

    async def find_page_by_post(self, post_id: str, skip: int, limit: int) -> tuple[list[Comment], int]:
        query = {"post_id": post_id}
        total = await self.count(query)
        comments = await self.find_page(query, skip=skip, limit=limit, sort=-Comment.id)
        return comments, total
