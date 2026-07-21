from pydantic import BaseModel, EmailStr


class CreateUser(BaseModel):
    name: str
    lastname: str
    email: EmailStr
    password: str


class LoginUser(BaseModel):
    email: EmailStr
    password: str


class UpdateUser(BaseModel):
    name: str | None = None
    lastname: str | None = None
    password: str | None = None
    Bio: str | None = None
    image: str | None = None