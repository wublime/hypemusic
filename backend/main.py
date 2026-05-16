import os
import re
import time
import uuid
from contextlib import asynccontextmanager

import httpx
import uvicorn
from fastapi import Depends, FastAPI, Header, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from auth import create_app_jwt, get_current_user, verify_apple_identity_token
from database import Base, engine, ensure_schema, get_db
from models import DropRequest, Release, User  # noqa: F401  (models registered on Base)
from schemas import (
    AlbumOut,
    AppleAuthIn,
    AppleAuthOut,
    DevAuthIn,
    ArtistOut,
    CheckUsernameOut,
    DropRequestAdminOut,
    DropRequestCreateIn,
    DropRequestCreatedOut,
    SongOut,
    SpotifyExchangeIn,
    SpotifyExchangeOut,
    UpdateUserIn,
    UserOut,
    USERNAME_PATTERN,
    user_to_out,
)
from spotify_service import spotify_service
from spotify_user import (
    fetch_currently_playing,
    parse_currently_playing_payload,
    refresh_user_access_token,
)

# Per ``friend_id`` (``str`` user UUID) fire counts. Solo dev: only your row appears;
# when you add friends, any authenticated user can react to any listed ``user_id``.
NOW_PLAYING_REACTIONS: dict[str, dict[str, int | bool]] = {}


def _reaction_row(friend_id: str) -> dict[str, int | bool]:
    if friend_id not in NOW_PLAYING_REACTIONS:
        NOW_PLAYING_REACTIONS[friend_id] = {"fire_count": 0, "viewer_reacted": False}
    return NOW_PLAYING_REACTIONS[friend_id]


def _utc_timestamp() -> str:
    from datetime import datetime, timezone

    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _feed_row(
    user: User,
    *,
    song_title: str,
    artist_name: str,
    artwork_url: str,
    is_playing: bool,
    progress_ms: int | None,
    duration_ms: int | None,
    progress_snapshot_ms: int | None,
) -> dict:
    uid = str(user.id)
    handle = f"@{user.username}" if user.username else "@you"
    r = _reaction_row(uid)
    row: dict = {
        "user_id": uid,
        "username": handle,
        "song_title": song_title,
        "artist_name": artist_name,
        "artwork_url": artwork_url,
        "is_playing": is_playing,
        "updated_at": _utc_timestamp(),
        "fire_count": int(r["fire_count"]),
        "viewer_reacted": bool(r["viewer_reacted"]),
    }
    if progress_ms is not None:
        row["progress_ms"] = progress_ms
    if duration_ms is not None:
        row["duration_ms"] = duration_ms
    if progress_snapshot_ms is not None:
        row["progress_snapshot_ms"] = progress_snapshot_ms
    return row


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    ensure_schema()
    yield


app = FastAPI(lifespan=lifespan)


def _release_to_api_dict(r: Release) -> dict:
    return {
        "title": r.title,
        "artist": r.artist,
        "artwork_url": r.artwork_url,
        "hype_count": r.hype_count,
        "release_date": r.release_date.isoformat() if r.release_date else None,
        "status": r.status,
        "countdown": r.countdown,
    }


@app.get("/releases")
def get_releases(db: Session = Depends(get_db)):
    rows = db.scalars(select(Release).order_by(Release.id)).all()
    return [_release_to_api_dict(r) for r in rows]


@app.post("/releases/drop-requests", response_model=DropRequestCreatedOut)
def create_drop_request(
    body: DropRequestCreateIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    album_title = body.album_title.strip()
    artist_name = body.artist_name.strip()
    if not album_title or not artist_name:
        raise HTTPException(
            status_code=422,
            detail="Album title and artist name cannot be empty",
        )
    note_raw = (body.note or "").strip()
    note = note_raw or None

    row = DropRequest(
        user_id=current_user.id,
        album_title=album_title,
        artist_name=artist_name,
        note=note,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return DropRequestCreatedOut(id=row.id)


@app.get("/admin/drop-requests", response_model=list[DropRequestAdminOut])
def list_drop_requests_for_admin(
    db: Session = Depends(get_db),
    x_admin_secret: str | None = Header(default=None, alias="X-Admin-Secret"),
):
    """List recent suggestions. Set `ADMIN_DROP_REQUEST_SECRET` in the server
    env and pass the same value in the ``X-Admin-Secret`` header (e.g. curl).
    """
    expected = (os.environ.get("ADMIN_DROP_REQUEST_SECRET") or "").strip()
    if not expected or (x_admin_secret or "").strip() != expected:
        raise HTTPException(status_code=401, detail="Unauthorized")

    stmt = (
        select(DropRequest, User.username, User.email)
        .join(User, User.id == DropRequest.user_id)
        .order_by(DropRequest.created_at.desc())
        .limit(500)
    )
    rows = db.execute(stmt).all()
    return [
        DropRequestAdminOut(
            id=dr.id,
            user_id=dr.user_id,
            username=username,
            email=email,
            album_title=dr.album_title,
            artist_name=dr.artist_name,
            note=dr.note,
            created_at=dr.created_at,
        )
        for dr, username, email in rows
    ]


@app.get("/feed/now-playing")
def get_feed_now_playing(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Live Hype Feed row for the signed-in user (Spotify currently playing)."""
    db.refresh(current_user)
    if not current_user.spotify_refresh_token:
        return [
            _feed_row(
                current_user,
                song_title="Connect Spotify",
                artist_name="Open Profile → Music services to link your account",
                artwork_url="",
                is_playing=False,
                progress_ms=None,
                duration_ms=None,
                progress_snapshot_ms=None,
            )
        ]

    try:
        access, new_refresh = refresh_user_access_token(current_user.spotify_refresh_token)
        if new_refresh:
            current_user.spotify_refresh_token = new_refresh
            db.commit()
    except HTTPException as exc:
        # Missing server config must surface; Spotify refresh failures become feed UX,
        # not a generic 502 for the whole tab.
        if exc.status_code == 503:
            raise
        return [
            _feed_row(
                current_user,
                song_title="Reconnect Spotify",
                artist_name="We couldn’t refresh your Spotify session — open Profile and link again.",
                artwork_url="",
                is_playing=False,
                progress_ms=None,
                duration_ms=None,
                progress_snapshot_ms=None,
            )
        ]
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Spotify token failed: {e}")

    body, status = fetch_currently_playing(access)
    if status == 401:
        return [
            _feed_row(
                current_user,
                song_title="Reconnect Spotify",
                artist_name="Your session expired — link again from Profile",
                artwork_url="",
                is_playing=False,
                progress_ms=None,
                duration_ms=None,
                progress_snapshot_ms=None,
            )
        ]

    if body is None:
        if status == 204:
            now_ms = int(time.time() * 1000)
            return [
                _feed_row(
                    current_user,
                    song_title="Nothing playing",
                    artist_name="Start a track in Spotify on this phone",
                    artwork_url="",
                    is_playing=False,
                    progress_ms=0,
                    duration_ms=0,
                    progress_snapshot_ms=now_ms,
                )
            ]
        return [
            _feed_row(
                current_user,
                song_title="Couldn’t reach Spotify",
                artist_name="Check your connection and try again",
                artwork_url="",
                is_playing=False,
                progress_ms=None,
                duration_ms=None,
                progress_snapshot_ms=None,
            )
        ]

    parsed = parse_currently_playing_payload(body)
    snap = int(parsed.get("progress_snapshot_ms") or 0)
    if snap <= 0:
        snap = int(time.time() * 1000)

    return [
        _feed_row(
            current_user,
            song_title=str(parsed["song_title"]),
            artist_name=str(parsed["artist_name"]),
            artwork_url=str(parsed["artwork_url"]),
            is_playing=bool(parsed["is_playing"]),
            progress_ms=int(parsed["progress_ms"]),
            duration_ms=int(parsed["duration_ms"]),
            progress_snapshot_ms=snap,
        )
    ]


@app.post("/feed/now-playing/{friend_id}/react")
def react_fire(
    friend_id: str,
    current_user: User = Depends(get_current_user),
):
    row = _reaction_row(friend_id)
    was_reacted = bool(row["viewer_reacted"])
    row["viewer_reacted"] = not was_reacted
    if row["viewer_reacted"] and not was_reacted:
        row["fire_count"] = int(row["fire_count"]) + 1
    elif was_reacted and not row["viewer_reacted"]:
        row["fire_count"] = max(0, int(row["fire_count"]) - 1)
    return {
        "fire_count": int(row["fire_count"]),
        "viewer_reacted": bool(row["viewer_reacted"]),
    }


def _issue_auth_response(user: User) -> AppleAuthOut:
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

    return _issue_auth_response(user)


DEV_AUTH_ENABLED = os.environ.get("DEV_AUTH_ENABLED", "0") == "1"


@app.post("/auth/dev", response_model=AppleAuthOut)
def auth_dev(body: DevAuthIn = DevAuthIn(), db: Session = Depends(get_db)):
    """Local-only session minting when Apple verification is unavailable."""
    if not DEV_AUTH_ENABLED:
        raise HTTPException(status_code=404, detail="Not found")
    apple_sub = f"dev-{uuid.uuid4()}"
    user = User(apple_user_id=apple_sub, email=body.email, favorite_genres=[])
    db.add(user)
    db.commit()
    db.refresh(user)
    return _issue_auth_response(user)


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


# ---------------------------------------------------------------------------
# Spotify search (server-to-server Client Credentials flow)
# ---------------------------------------------------------------------------


@app.get("/api/search/albums", response_model=list[AlbumOut])
def search_albums(query: str):
    """Proxy Spotify's /v1/search?type=album behind our own server.

    Keeping this server-side means: (a) the client never sees Spotify
    credentials, (b) we can layer rate limiting/caching later without an
    iOS release, and (c) we can mix Spotify results with our own DB.
    """
    return spotify_service.search_albums(query)


@app.get("/api/search/artists", response_model=list[ArtistOut])
def search_artists(query: str):
    """Proxy Spotify's /v1/search?type=artist."""
    return spotify_service.search_artists(query)


@app.get("/api/search/songs", response_model=list[SongOut])
def search_songs(query: str):
    """Proxy Spotify's /v1/search?type=track.

    Exposed as "songs" because that's the user-facing term in the app.
    """
    return spotify_service.search_songs(query)


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
