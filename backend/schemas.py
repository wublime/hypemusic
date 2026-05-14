"""Pydantic request/response models for the user/auth surface."""

from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field

from models import User


USERNAME_PATTERN = r"^[a-z0-9_]{3,20}$"


class UserOut(BaseModel):
    id: UUID
    email: Optional[str] = None
    username: Optional[str] = None
    avatar_url: Optional[str] = None
    favorite_genres: list[str] = []
    onboarding_complete: bool = False
    spotify_connected: bool = False
    apple_music_connected: bool = False
    created_at: datetime


def user_to_out(u: User) -> UserOut:
    return UserOut(
        id=u.id,
        email=u.email,
        username=u.username,
        avatar_url=u.avatar_url,
        favorite_genres=list(u.favorite_genres or []),
        onboarding_complete=u.onboarding_complete,
        spotify_connected=u.spotify_refresh_token is not None,
        apple_music_connected=u.apple_music_user_token is not None,
        created_at=u.created_at,
    )


class AppleAuthIn(BaseModel):
    identity_token: str
    nonce: Optional[str] = None
    # Apple returns email only on first authorization. Client may pass it through.
    email: Optional[str] = None


class AppleAuthOut(BaseModel):
    access_token: str
    user: UserOut


class DevAuthIn(BaseModel):
    """Dev-only: lets the simulator/free-team build mint a session without Apple."""

    device_id: str = Field(min_length=1, max_length=128)
    email: Optional[str] = None


class UpdateUserIn(BaseModel):
    username: Optional[str] = Field(default=None, pattern=USERNAME_PATTERN)
    favorite_genres: Optional[list[str]] = None
    onboarding_complete: Optional[bool] = None


class SpotifyExchangeIn(BaseModel):
    code: str
    code_verifier: str
    redirect_uri: str


class SpotifyExchangeOut(BaseModel):
    connected: bool


class CheckUsernameOut(BaseModel):
    available: bool


class AlbumOut(BaseModel):
    """Simplified album record returned by `/api/search/albums`.

    Mirrors what the iOS `Album` struct expects: just enough to render a
    card (cover + name + artist + year).
    """

    name: str
    artist: str
    release_date: str
    spotify_id: str
    image_url: Optional[str] = None


class ArtistOut(BaseModel):
    """Simplified artist record returned by `/api/search/artists`."""

    name: str
    spotify_id: str
    image_url: Optional[str] = None
    genres: list[str] = []
    follower_count: Optional[int] = None


class SongOut(BaseModel):
    """Simplified track record returned by `/api/search/songs`.

    Spotify calls these "tracks"; we expose them as "songs" because that's
    the term the user-facing UI uses.
    """

    name: str
    artist: str
    album: str
    release_date: str
    spotify_id: str
    image_url: Optional[str] = None
    preview_url: Optional[str] = None
    duration_ms: int = 0
