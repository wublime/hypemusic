from fastapi import FastAPI
import uvicorn

app = FastAPI()

# This is the "Menu" your iPhone app will eventually read
@app.get("/releases")
def get_releases():
    return [
        {
            "title": "CHROMAKOPIA",
            "artist": "Tyler, The Creator",
            "hype_score": 98,
            "status": "Dropping Soon",
            "countdown": "9D 14H" # Add this key
        },
        {
            "title": "Haram",
            "artist": "Armand Hammer",
            "hype_score": 92,
            "status": "Released",
            "countdown": "9D 14H" # Add this key
        },
        {
            "title": "Pray for Paris",
            "artist": "Westside Gunn",
            "hype_score": 90,
            "status": "Dropping Soon",
            "countdown": "16D 14H" # Add this key
        }
    ]



if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
