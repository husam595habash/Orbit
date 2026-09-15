from pydantic import BaseModel, EmailStr


class CreateUser(BaseModel):
    firstname: str
    lastname: str
    username: str
    email: EmailStr
    password: str


class LoginUser(BaseModel):
    email: EmailStr
    password: str


class GoogleAuthRequest(BaseModel):
    id_token: str


class UpdateUser(BaseModel):
    firstname: str | None = None
    lastname: str | None = None
    username: str | None = None
    password: str | None = None
    Bio: str | None = None
    image: str | None = None