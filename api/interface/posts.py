from pydantic import BaseModel

class CreatePost(BaseModel):
    title: str
    message: str
    selectedFile: str | None = None

class UpdatePost(BaseModel):
    title: str | None = None
    message: str | None = None
    selectedFile: str | None = None

class CreateComment(BaseModel):
    value: str


