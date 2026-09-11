from decouple import config
from slowapi import Limiter
from slowapi.util import get_remote_address

REDIS_URI = config("REDIS_URI", default="redis://localhost:6379")

limiter = Limiter(key_func=get_remote_address, storage_uri=REDIS_URI)
