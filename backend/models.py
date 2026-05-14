import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, Integer, String, Text, func, text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from database import Base


class Release(Base):
    __tablename__ = "releases"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    title: Mapped[str] = mapped_column(String(512), nullable=False)
    artist: Mapped[str] = mapped_column(String(512), nullable=False)
    hype_count: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, server_default=text("0")
    )
    artwork_url: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(String(128), nullable=False)
    countdown: Mapped[str] = mapped_column(String(128), nullable=False)


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    apple_user_id: Mapped[str] = mapped_column(
        String(255), unique=True, nullable=False, index=True
    )
    email: Mapped[Optional[str]] = mapped_column(String(320), nullable=True)
    # username doubles as display name (lowercase, 3-20 chars, [a-z0-9_])
    username: Mapped[Optional[str]] = mapped_column(
        String(20), unique=True, nullable=True, index=True
    )
    avatar_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    favorite_genres: Mapped[list] = mapped_column(
        JSONB, nullable=False, default=list, server_default=text("'[]'::jsonb")
    )
    onboarding_complete: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, server_default=text("false")
    )
    spotify_refresh_token: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    apple_music_user_token: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )
