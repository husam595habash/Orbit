from beanie import init_beanie
from models.users import User


async def init_db():
    await init_beanie(
        connection_string="mongodb://localhost:27017/social",
        document_models=[User]
    )