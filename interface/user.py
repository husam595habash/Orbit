from pydantic import BaseModel, EmailStr


class CreateUser(BaseModel):
    name: str
    lastname: str
    email: EmailStr
    password: str
