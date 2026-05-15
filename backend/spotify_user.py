"""Spotify Web API calls on behalf of a linked user (refresh token → access token)."""

from __future__ import annotations

import os
from typing import Any, Optional, Tuple

import httpx
from fastapi import HTTPException

SPOTIFY_TOKEN_URL = "https://accounts.spotify.com/api/token"
SPOTIFY_CURRENTLY_PLAYING = "https://api.spotify.com/v1/me/player/currently-playing"


def refresh_user_access_token(refresh_token: str) -> Tuple[str, Optional[str]]:
    """Swap refresh token for access token.

    Returns ``(access_token, new_refresh_token_or_none)``. Spotify may rotate
    refresh tokens; when ``new_refresh_token_or_none`` is set, callers must
    persist it and stop using the previous refresh token.

    Tokens from our PKCE link flow must be refreshed **without** HTTP Basic auth —
    only ``grant_type``, ``refresh_token``, and ``client_id`` in the form body
    (see Spotify's PKCE refresh example). Sending ``client_secret`` via Basic has
    been observed to break refresh for PKCE-issued tokens.

    If a ``SPOTIFY_CLIENT_SECRET`` is configured, we retry with Basic auth so
    older confidential-client refresh tokens still work.
    """
    client_id = (os.environ.get("SPOTIFY_CLIENT_ID") or "").strip()
    client_secret = (os.environ.get("SPOTIFY_CLIENT_SECRET") or "").strip()
    if not client_id:
        raise HTTPException(status_code=503, detail="Spotify is not configured on the server")

    refresh_token = refresh_token.strip()
    if not refresh_token:
        raise HTTPException(status_code=502, detail="Spotify refresh token is empty")

    form = {
        "grant_type": "refresh_token",
        "refresh_token": refresh_token,
        "client_id": client_id,
    }

    with httpx.Client(timeout=15.0) as client:
        resp = client.post(SPOTIFY_TOKEN_URL, data=form)
        if resp.status_code != 200 and client_secret:
            resp = client.post(
                SPOTIFY_TOKEN_URL,
                data=form,
                auth=(client_id, client_secret),
            )
    if resp.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"Spotify token refresh failed: {resp.text}",
        )
    data = resp.json()
    access = data.get("access_token")
    if not access:
        raise HTTPException(status_code=502, detail="Spotify refresh returned no access_token")
    rotated = data.get("refresh_token")
    new_refresh: Optional[str] = None
    if rotated is not None:
        s = str(rotated).strip()
        if s:
            new_refresh = s
    return str(access), new_refresh


def fetch_currently_playing(access_token: str) -> tuple[Optional[dict[str, Any]], int]:
    """Call Spotify currently-playing. Returns ``(body_dict, status_code)``.
    ``body_dict`` is ``None`` for HTTP 204 (no active playback).
    """
    with httpx.Client(timeout=15.0) as client:
        resp = client.get(
            SPOTIFY_CURRENTLY_PLAYING,
            headers={"Authorization": f"Bearer {access_token}"},
        )
    if resp.status_code == 204:
        return None, 204
    if resp.status_code == 401:
        return None, 401
    if resp.status_code != 200:
        return None, resp.status_code
    try:
        return resp.json(), 200
    except Exception:
        return None, resp.status_code


def parse_currently_playing_payload(payload: dict[str, Any]) -> dict[str, Any]:
    """Normalize Spotify JSON into hype-feed row fields (track metadata + progress)."""
    item = payload.get("item")
    if not isinstance(item, dict):
        return {
            "song_title": "Nothing playing",
            "artist_name": "Start a track in Spotify",
            "artwork_url": "",
            "is_playing": bool(payload.get("is_playing")),
            "progress_ms": int(payload.get("progress_ms") or 0),
            "duration_ms": 0,
            "progress_snapshot_ms": int(payload.get("timestamp") or 0),
        }

    if item.get("type") != "track":
        return {
            "song_title": "Playing something else",
            "artist_name": "Open Spotify for track details",
            "artwork_url": "",
            "is_playing": bool(payload.get("is_playing")),
            "progress_ms": int(payload.get("progress_ms") or 0),
            "duration_ms": 0,
            "progress_snapshot_ms": int(payload.get("timestamp") or 0),
        }

    artists = item.get("artists") or []
    artist_name = ", ".join(a.get("name", "") for a in artists if isinstance(a, dict)).strip() or "Unknown"

    album = item.get("album") or {}
    images = album.get("images") or []
    artwork_url = ""
    if images:
        sorted_imgs = sorted(
            (i for i in images if isinstance(i, dict) and i.get("url")),
            key=lambda i: int(i.get("width") or 0),
            reverse=True,
        )
        if sorted_imgs:
            artwork_url = str(sorted_imgs[0].get("url", ""))

    duration_ms = int(item.get("duration_ms") or 0)
    return {
        "song_title": str(item.get("name") or "Unknown track"),
        "artist_name": artist_name,
        "artwork_url": artwork_url,
        "is_playing": bool(payload.get("is_playing")),
        "progress_ms": int(payload.get("progress_ms") or 0),
        "duration_ms": duration_ms,
        "progress_snapshot_ms": int(payload.get("timestamp") or 0),
    }
