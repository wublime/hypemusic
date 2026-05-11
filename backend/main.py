from fastapi import FastAPI, HTTPException
import uvicorn

app = FastAPI()

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


# This is the "Menu" your iPhone app will eventually read
@app.get("/releases")
def get_releases():
    return [
        {
            "title": "CHROMAKOPIA",
            "artist": "Tyler, The Creator",
            "hype_score": 98,
            "status": "Dropping Soon",
            "countdown": "9D 14H"  # Add this key
        },
        {
            "title": "Haram",
            "artist": "Armand Hammer",
            "hype_score": 92,
            "status": "Released",
            "countdown": "9D 14H"  # Add this key
        },
        {
            "title": "Pray for Paris",
            "artist": "Westside Gunn",
            "hype_score": 90,
            "status": "Dropping Soon",
            "countdown": "16D 14H"  # Add this key
        }
    ]


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


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
