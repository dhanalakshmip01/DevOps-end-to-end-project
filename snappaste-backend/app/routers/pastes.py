from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from nanoid import generate
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Paste
from app.schemas import ExpiryOption, PasteCreate, PasteResponse

router = APIRouter(prefix="/api/pastes", tags=["pastes"])

_EXPIRY_DELTAS: dict[ExpiryOption, timedelta | None] = {
    ExpiryOption.ONE_HOUR: timedelta(hours=1),
    ExpiryOption.ONE_DAY: timedelta(days=1),
    ExpiryOption.ONE_WEEK: timedelta(weeks=1),
    ExpiryOption.NEVER: None,
}


def _compute_expires_at(expiry: ExpiryOption) -> datetime | None:
    delta = _EXPIRY_DELTAS[expiry]
    return datetime.now(UTC) + delta if delta else None


def _get_paste_or_404(short_code: str, db: Session) -> Paste:
    paste = db.query(Paste).filter(Paste.short_code == short_code).first()
    if not paste:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Paste not found")
    if paste.expires_at and paste.expires_at < datetime.now(UTC):
        db.delete(paste)
        db.commit()
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Paste has expired")
    return paste


@router.post("", response_model=PasteResponse, status_code=status.HTTP_201_CREATED)
def create_paste(payload: PasteCreate, db: Session = Depends(get_db)) -> Paste:
    paste = Paste(
        short_code=generate(size=8),
        title=payload.title,
        content=payload.content,
        language=payload.language.value,
        expires_at=_compute_expires_at(payload.expiry),
    )
    db.add(paste)
    db.commit()
    db.refresh(paste)
    return paste


@router.get("/{short_code}", response_model=PasteResponse)
def get_paste(short_code: str, db: Session = Depends(get_db)) -> Paste:
    paste = _get_paste_or_404(short_code, db)
    paste.view_count += 1
    db.commit()
    db.refresh(paste)
    return paste


@router.delete("/{short_code}", status_code=status.HTTP_204_NO_CONTENT)
def delete_paste(short_code: str, db: Session = Depends(get_db)) -> None:
    paste = _get_paste_or_404(short_code, db)
    db.delete(paste)
    db.commit()
