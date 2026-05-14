"""Spotify Web API access via Client Credentials Flow.

Server-to-server flow: the backend holds the client_id/secret, mints an
app-level access token (no user context), and uses it for endpoints that
don't need user data (search, audio features, etc.). Tokens last 1 hour
and are cached in-memory until they're close to expiring.
"""

from __future__ import annotations

import base64
import os
import threading
import time
from typing import Any, Optional

import httpx
from fastapi import HTTPException

SPOTIFY_TOKEN_URL = "https://accounts.spotify.com/api/token"
SPOTIFY_API_BASE = "https://api.spotify.com/v1"

# Refresh the cached token a minute before its real expiry to avoid races
# where we hand out a token that expires mid-request.
TOKEN_REFRESH_LEEWAY_SECONDS = 60


class SpotifyService:
    """Wraps Spotify's app-level (Client Credentials) API surface."""

    def __init__(
        self,
        client_id: Optional[str] = None,
        client_secret: Optional[str] = None,
    ) -> None:
        self._client_id = client_id or os.environ.get("SPOTIFY_CLIENT_ID")
        self._client_secret = client_secret or os.environ.get("SPOTIFY_CLIENT_SECRET")
        # FastAPI sync handlers run in a threadpool, so token mutation must be
        # guarded. We use a re-entrant-free lock on purpose: refresh paths
        # should never call get_access_token recursively.
        self._lock = threading.Lock()
        self._token: Optional[str] = None
        self._token_expires_at: float = 0.0

    # ------------------------------------------------------------------
    # Token management
    # ------------------------------------------------------------------

    def _require_credentials(self) -> None:
        if not self._client_id or not self._client_secret:
            raise HTTPException(
                status_code=503,
                detail="Spotify is not configured on the server",
            )

    def get_access_token(self) -> str:
        """Return a valid bearer token, refreshing if necessary."""
        with self._lock:
            now = time.time()
            if (
                self._token
                and now < self._token_expires_at - TOKEN_REFRESH_LEEWAY_SECONDS
            ):
                return self._token

            self._require_credentials()
            basic = base64.b64encode(
                f"{self._client_id}:{self._client_secret}".encode()
            ).decode()
            with httpx.Client(timeout=10.0) as client:
                resp = client.post(
                    SPOTIFY_TOKEN_URL,
                    headers={"Authorization": f"Basic {basic}"},
                    data={"grant_type": "client_credentials"},
                )
            if resp.status_code != 200:
                raise HTTPException(
                    status_code=502,
                    detail=f"Spotify token request failed: {resp.text}",
                )
            payload = resp.json()
            self._token = payload["access_token"]
            self._token_expires_at = now + int(payload.get("expires_in", 3600))
            return self._token

    def _invalidate_token(self) -> None:
        with self._lock:
            self._token = None
            self._token_expires_at = 0.0

    # ------------------------------------------------------------------
    # API surface
    # ------------------------------------------------------------------

    # Spotify's docs say `limit` accepts 1-50, but as of 2026 the live
    # `/v1/search` endpoint rejects anything above 10 with `{"status":400,
    # "message":"Invalid limit"}`. Default to 10 and clamp aggressively so
    # callers can't trip the cap by accident.
    SEARCH_MAX_LIMIT = 10

    def _call_search(
        self, query: str, type_: str, limit: int
    ) -> dict[str, Any]:
        """Low-level wrapper around `/v1/search`.

        Returns the raw JSON payload (caller picks the right sub-object,
        e.g. `albums`, `artists`, `tracks`). Returns ``{}`` for empty
        queries so callers can skip a network round-trip.
        """
        query = (query or "").strip()
        if not query:
            return {}

        clamped_limit = max(1, min(int(limit), self.SEARCH_MAX_LIMIT))
        token = self.get_access_token()
        with httpx.Client(timeout=10.0) as client:
            resp = client.get(
                f"{SPOTIFY_API_BASE}/search",
                headers={"Authorization": f"Bearer {token}"},
                params={"q": query, "type": type_, "limit": clamped_limit},
            )

        if resp.status_code == 401:
            # Token revoked/expired server-side: clear cache so the next call
            # mints a fresh one. Bubble up as 502 so the client retries.
            self._invalidate_token()
            raise HTTPException(status_code=502, detail="Spotify auth expired")
        if resp.status_code != 200:
            raise HTTPException(
                status_code=502,
                detail=f"Spotify search failed: {resp.text}",
            )
        return resp.json()

    def search_albums(self, query: str, limit: int = 10) -> list[dict[str, Any]]:
        """Search Spotify for albums. Returns simplified
        ``{name, artist, release_date, spotify_id, image_url}`` records.
        """
        payload = self._call_search(query, "album", limit)
        items = payload.get("albums", {}).get("items", []) if payload else []
        return [self._simplify_album(item) for item in items]

    def search_artists(self, query: str, limit: int = 10) -> list[dict[str, Any]]:
        """Search Spotify for artists. Returns simplified
        ``{name, spotify_id, image_url, genres, follower_count}`` records.
        """
        payload = self._call_search(query, "artist", limit)
        items = payload.get("artists", {}).get("items", []) if payload else []
        return [self._simplify_artist(item) for item in items]

    def search_songs(self, query: str, limit: int = 10) -> list[dict[str, Any]]:
        """Search Spotify for tracks (we surface them as "songs").

        Returns simplified ``{name, artist, album, release_date, spotify_id,
        image_url, preview_url, duration_ms}`` records.
        """
        payload = self._call_search(query, "track", limit)
        items = payload.get("tracks", {}).get("items", []) if payload else []
        return [self._simplify_song(item) for item in items]

    # ------------------------------------------------------------------
    # Item-shape helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _simplify_album(item: dict[str, Any]) -> dict[str, Any]:
        artists = item.get("artists") or []
        artist = ", ".join(a.get("name", "") for a in artists) or "Unknown"
        images = item.get("images") or []
        # Spotify returns largest image first; fall back to None for the
        # rare unreleased album with no artwork.
        image_url = images[0]["url"] if images else None
        return {
            "name": item.get("name", ""),
            "artist": artist,
            "release_date": item.get("release_date", ""),
            "spotify_id": item.get("id", ""),
            "image_url": image_url,
        }

    @staticmethod
    def _simplify_artist(item: dict[str, Any]) -> dict[str, Any]:
        images = item.get("images") or []
        image_url = images[0]["url"] if images else None
        followers = (item.get("followers") or {}).get("total")
        return {
            "name": item.get("name", ""),
            "spotify_id": item.get("id", ""),
            "image_url": image_url,
            "genres": list(item.get("genres") or []),
            "follower_count": int(followers) if followers is not None else None,
        }

    @staticmethod
    def _simplify_song(item: dict[str, Any]) -> dict[str, Any]:
        artists = item.get("artists") or []
        artist = ", ".join(a.get("name", "") for a in artists) or "Unknown"
        album = item.get("album") or {}
        album_images = album.get("images") or []
        # Tracks inherit their artwork from the album they belong to.
        image_url = album_images[0]["url"] if album_images else None
        return {
            "name": item.get("name", ""),
            "artist": artist,
            "album": album.get("name", ""),
            "release_date": album.get("release_date", ""),
            "spotify_id": item.get("id", ""),
            "image_url": image_url,
            "preview_url": item.get("preview_url"),
            "duration_ms": int(item.get("duration_ms") or 0),
        }


# Shared instance used by FastAPI handlers. Safe to import at module scope
# because credentials are pulled lazily from `os.environ` at construction time
# (which runs after `python-dotenv` has loaded the .env via uvicorn startup).
spotify_service = SpotifyService()
