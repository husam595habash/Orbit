import time
from typing import Dict, Optional
import jwt
from decouple import config

JWT_SECRET = config("secret")
JWT_ALGORITHM = config("algorithm")

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
