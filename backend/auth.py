"""Apple Sign In verification, app-issued JWT, and FastAPI auth dependency."""

from __future__ import annotations

import os
import time
import uuid
from typing import Optional

import jwt
from fastapi import Depends, Header, HTTPException, status
from jwt import PyJWKClient
from sqlalchemy.orm import Session

from database import get_db
from models import User

JWT_SECRET = os.environ.get("JWT_SECRET", "dev-secret-change-me")
JWT_ALG = "HS256"
JWT_TTL_SECONDS = 60 * 60 * 24 * 30  # 30 days

APPLE_ISSUER = "https://appleid.apple.com"
APPLE_AUDIENCE = os.environ.get("APPLE_AUDIENCE", "com.jacobhancock.HypeMusic")
APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys"


_jwk_client: Optional[PyJWKClient] = None


def _get_jwk_client() -> PyJWKClient:
    global _jwk_client
    if _jwk_client is None:
        # PyJWKClient caches keys in-memory by default.
        _jwk_client = PyJWKClient(APPLE_JWKS_URL)
    return _jwk_client


def verify_apple_identity_token(identity_token: str) -> dict:
    """Verify Apple's identity token signature, issuer, audience, expiry.

    Returns the decoded payload (contains `sub`, optionally `email`).
    """
    try:
        signing_key = _get_jwk_client().get_signing_key_from_jwt(identity_token).key
        payload = jwt.decode(
            identity_token,
            signing_key,
            algorithms=["RS256"],
            audience=APPLE_AUDIENCE,
            issuer=APPLE_ISSUER,
        )
        return payload
    except jwt.PyJWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Apple identity token: {e}",
        )


def create_app_jwt(user_id: str) -> str:
    now = int(time.time())
    payload = {"sub": user_id, "iat": now, "exp": now + JWT_TTL_SECONDS}
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALG)


def decode_app_jwt(token: str) -> dict:
    try:
        return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALG])
    except jwt.PyJWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {e}",
        )


def get_current_user(
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
) -> User:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing bearer token",
        )
    token = authorization.split(" ", 1)[1].strip()
    payload = decode_app_jwt(token)
    raw_sub = payload.get("sub")
    if not raw_sub:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing subject",
        )
    try:
        user_id = uuid.UUID(raw_sub)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid subject",
        )
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )
    return user
