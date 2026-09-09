from fastapi import Request, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from auth.auth_handler import decodeJWT



class JWTBearer(HTTPBearer):
    def __init__(self, auto_error: bool = True):
        super(JWTBearer, self).__init__(auto_error=auto_error)

    async def __call__(self, request: Request) -> dict:
        credentials: HTTPAuthorizationCredentials = await super(JWTBearer, self).__call__(request)
        if not credentials:
            raise HTTPException(status_code=401, detail="Invalid authorization code.")
        if not credentials.scheme == "Bearer":
            raise HTTPException(status_code=401, detail="Invalid authentication scheme.")

        payload = decodeJWT(credentials.credentials)
        if not payload:
            raise HTTPException(status_code=401, detail="Invalid token or expired token.")
        return payload


async def get_current_user_id(payload: dict = Depends(JWTBearer())) -> str:
    return payload["user_id"]
