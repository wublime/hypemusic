import os
import re
from contextlib import asynccontextmanager

import httpx
import uvicorn
from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from auth import create_app_jwt, get_current_user, verify_apple_identity_token
from database import Base, engine, get_db
from models import Release, User  # noqa: F401  (Release/User registered on Base)
from schemas import (
    AppleAuthIn,
    AppleAuthOut,
    CheckUsernameOut,
    DevAuthIn,
    SpotifyExchangeIn,
    SpotifyExchangeOut,
    UpdateUserIn,
    UserOut,
    USERNAME_PATTERN,
    user_to_out,
)

NOW_PLAYING_FEED = [
    {
        "user_id": "user_alex",
        "username": "@alexm",
        "song_title": "FE!N",
        "artist_name": "Travis Scott",
        "artwork_url": "https://picsum.photos/seed/hypealex/600/600",
        "is_playing": True,
        "updated_at": "2026-05-09T12:00:00Z",
        "fire_count": 14,
        "viewer_reacted": False,
    },
    {
        "user_id": "user_nina",
        "username": "@ninab",
        "song_title": "Vampire",
        "artist_name": "Olivia Rodrigo",
        "artwork_url": "https://picsum.photos/seed/hypenina/600/600",
        "is_playing": True,
        "updated_at": "2026-05-09T12:02:00Z",
        "fire_count": 31,
        "viewer_reacted": True,
    },
    {
        "user_id": "user_jo",
        "username": "@jothekid",
        "song_title": "SICKO MODE",
        "artist_name": "Travis Scott",
        "artwork_url": "https://picsum.photos/seed/hypejo/600/600",
        "is_playing": False,
        "updated_at": "2026-05-09T11:45:00Z",
        "fire_count": 8,
        "viewer_reacted": False,
    },
    {
        "user_id": "user_maya",
        "username": "@mayacodes",
        "song_title": "After Hours",
        "artist_name": "The Weeknd",
        "artwork_url": "https://picsum.photos/seed/hypemaya/600/600",
        "is_playing": True,
        "updated_at": "2026-05-09T12:05:00Z",
        "fire_count": 22,
        "viewer_reacted": False,
    },
]


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(lifespan=lifespan)


def _release_to_api_dict(r: Release) -> dict:
    return {
        "title": r.title,
        "artist": r.artist,
        "artwork_url": r.artwork_url,
        "hype_count": r.hype_count,
        "status": r.status,
        "countdown": r.countdown,
    }


@app.get("/releases")
def get_releases(db: Session = Depends(get_db)):
    rows = db.scalars(select(Release).order_by(Release.id)).all()
    return [_release_to_api_dict(r) for r in rows]


@app.get("/feed/now-playing")
def get_feed_now_playing():
    return NOW_PLAYING_FEED


@app.post("/feed/now-playing/{friend_id}/react")
def react_fire(friend_id: str):
    for row in NOW_PLAYING_FEED:
        if row["user_id"] == friend_id:
            was_reacted = row["viewer_reacted"]
            row["viewer_reacted"] = not was_reacted
            if row["viewer_reacted"] and not was_reacted:
                row["fire_count"] += 1
            elif was_reacted and not row["viewer_reacted"]:
                row["fire_count"] = max(0, row["fire_count"] - 1)
            return {
                "fire_count": row["fire_count"],
                "viewer_reacted": row["viewer_reacted"],
            }
    raise HTTPException(status_code=404, detail="friend not found")


# ---------------------------------------------------------------------------
# Auth + onboarding
# ---------------------------------------------------------------------------


def _dev_auth_enabled() -> bool:
    return os.environ.get("DEV_AUTH_ENABLED", "").lower() in {"1", "true", "yes"}


@app.post("/auth/dev", response_model=AppleAuthOut)
def auth_dev(body: DevAuthIn, db: Session = Depends(get_db)):
    """Sign in without Apple. Gated by `DEV_AUTH_ENABLED=1` so it cannot be
    abused in production. Upserts a `User` keyed on `dev:<device_id>` so the
    same simulator/device keeps the same account across launches.
    """
    if not _dev_auth_enabled():
        raise HTTPException(status_code=404, detail="Not Found")

    synthetic_sub = f"dev:{body.device_id}"
    user = db.scalar(select(User).where(User.apple_user_id == synthetic_sub))
    if user is None:
        user = User(apple_user_id=synthetic_sub, email=body.email, favorite_genres=[])
        db.add(user)
        db.commit()
        db.refresh(user)
    elif body.email and not user.email:
        user.email = body.email
        db.commit()
        db.refresh(user)

    token = create_app_jwt(str(user.id))
    return AppleAuthOut(access_token=token, user=user_to_out(user))


@app.post("/auth/apple", response_model=AppleAuthOut)
def auth_apple(body: AppleAuthIn, db: Session = Depends(get_db)):
    payload = verify_apple_identity_token(body.identity_token)
    apple_sub = payload["sub"]
    email_from_apple = payload.get("email")
    email = body.email or email_from_apple

    user = db.scalar(select(User).where(User.apple_user_id == apple_sub))
    if user is None:
        user = User(apple_user_id=apple_sub, email=email, favorite_genres=[])
        db.add(user)
        db.commit()
        db.refresh(user)
    elif email and not user.email:
        user.email = email
        db.commit()
        db.refresh(user)

    token = create_app_jwt(str(user.id))
    return AppleAuthOut(access_token=token, user=user_to_out(user))


@app.get("/users/me", response_model=UserOut)
def get_me(current_user: User = Depends(get_current_user)):
    return user_to_out(current_user)


@app.patch("/users/me", response_model=UserOut)
def update_me(
    body: UpdateUserIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if body.username is not None:
        normalized = body.username.lower().strip()
        existing = db.scalar(
            select(User).where(
                User.username == normalized,
                User.id != current_user.id,
            )
        )
        if existing is not None:
            raise HTTPException(status_code=409, detail="Username already taken")
        current_user.username = normalized

    if body.favorite_genres is not None:
        # Drop dupes, normalize to lowercase, keep order.
        seen: set[str] = set()
        cleaned: list[str] = []
        for g in body.favorite_genres:
            key = g.lower().strip()
            if key and key not in seen:
                seen.add(key)
                cleaned.append(key)
        current_user.favorite_genres = cleaned

    if body.onboarding_complete is not None:
        current_user.onboarding_complete = body.onboarding_complete

    db.commit()
    db.refresh(current_user)
    return user_to_out(current_user)


@app.get("/users/check-username", response_model=CheckUsernameOut)
def check_username(q: str, db: Session = Depends(get_db)):
    normalized = q.lower().strip()
    if not re.fullmatch(USERNAME_PATTERN, normalized):
        return CheckUsernameOut(available=False)
    existing = db.scalar(select(User).where(User.username == normalized))
    return CheckUsernameOut(available=existing is None)


@app.post("/auth/spotify/exchange", response_model=SpotifyExchangeOut)
def spotify_exchange(
    body: SpotifyExchangeIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    client_id = os.environ.get("SPOTIFY_CLIENT_ID")
    client_secret = os.environ.get("SPOTIFY_CLIENT_SECRET")
    if not client_id or not client_secret:
        raise HTTPException(status_code=503, detail="Spotify is not configured on the server")

    with httpx.Client(timeout=10.0) as client:
        resp = client.post(
            "https://accounts.spotify.com/api/token",
            data={
                "grant_type": "authorization_code",
                "code": body.code,
                "redirect_uri": body.redirect_uri,
                "code_verifier": body.code_verifier,
                "client_id": client_id,
            },
            auth=(client_id, client_secret),
        )
    if resp.status_code != 200:
        raise HTTPException(status_code=400, detail=f"Spotify token exchange failed: {resp.text}")
    tokens = resp.json()
    refresh = tokens.get("refresh_token")
    if not refresh:
        raise HTTPException(status_code=400, detail="No refresh token in Spotify response")

    current_user.spotify_refresh_token = refresh
    db.commit()
    return SpotifyExchangeOut(connected=True)


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
