from typing import Generic, Optional, TypeVar

from beanie import Document
from bson import ObjectId
from bson.errors import InvalidId

ModelType = TypeVar("ModelType", bound=Document)


class BaseRepository(Generic[ModelType]):

    model: type[ModelType]

    async def find_by_id(self, doc_id: str) -> Optional[ModelType]:
        try:
            object_id = ObjectId(doc_id)
        except InvalidId:
            return None
        return await self.model.find_one({"_id": object_id})

    async def find_by_ids(self, doc_ids: list[str], limit: Optional[int] = None) -> list[ModelType]:
        if not doc_ids:
            return []
        object_ids = [ObjectId(doc_id) for doc_id in doc_ids]
        query = self.model.find({"_id": {"$in": object_ids}})
        if limit is not None:
            query = query.limit(limit)
        return await query.to_list()

    async def count(self, query: dict) -> int:
        return await self.model.find(query).count()

    async def find_page(
        self,
        query: dict,
        skip: int = 0,
        limit: Optional[int] = None,
        sort: Optional[str] = None,
    ) -> list[ModelType]:
        cursor = self.model.find(query)
        if sort is not None:
            cursor = cursor.sort(sort)
        cursor = cursor.skip(skip)
        if limit is not None:
            cursor = cursor.limit(limit)
        return await cursor.to_list()

    async def save(self, doc: ModelType) -> ModelType:
        await doc.save()
        return doc

    async def insert(self, doc: ModelType) -> ModelType:
        await doc.insert()
        return doc

    async def delete(self, doc: ModelType) -> None:
        await doc.delete()
