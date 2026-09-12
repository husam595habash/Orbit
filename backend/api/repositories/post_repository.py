from models.post import Post
from repositories.base import BaseRepository


class PostRepository(BaseRepository[Post]):
    model = Post

    async def find_posts_page(self, query: dict, skip: int, limit: int) -> tuple[list[Post], int]:
        total = await self.count(query)
        posts = await self.find_page(query, skip=skip, limit=limit, sort=-Post.createdAt)
        return posts, total
