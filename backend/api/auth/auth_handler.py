import time
from typing import Dict, Optional
import jwt
from decouple import config
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests

from exceptions import UnauthorizedError

JWT_SECRET = config("secret")
JWT_ALGORITHM = config("algorithm")
GOOGLE_CLIENT_ID = config("google_client_id")

def token_response(token: str):
    return {
        "access_token": token
    }


# fun used for signing jwt token
def signJWT(user_id: str) -> Dict[str, str]:
    payload = {
        "user_id": user_id,
        "exp": int(time.time()) + 86400  # 24 hours
    }

    token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
    return token_response(token)



def decodeJWT(token: str) -> Optional[dict]:
    try:
        return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM], options={"require": ["exp"]})
    except jwt.PyJWTError:
        return None


# verify a Google Sign-In id token and pull out the fields we need to
# find-or-create a matching User
def verify_google_token(token: str) -> dict:
    try:
        payload = google_id_token.verify_oauth2_token(token, google_requests.Request(), GOOGLE_CLIENT_ID)
    except ValueError:
        raise UnauthorizedError("Invalid Google token")

    return {
        "email": payload["email"],
        "firstname": payload.get("given_name", ""),
        "lastname": payload.get("family_name", ""),
        "username": payload["email"].split("@")[0],
        "imageUrl": payload.get("picture", ""),
    }
