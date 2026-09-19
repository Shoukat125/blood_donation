from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from typing import Optional, List

import models
import schemas
from database import get_db
from routers.auth import get_current_user

router = APIRouter(prefix="/api/messages", tags=["Messages"])


def get_user_from_header(authorization: Optional[str] = Header(None), db: Session = Depends(get_db)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Not authenticated")
    token = authorization.split(" ")[1]
    return get_current_user(token, db)


# ── SEND MESSAGE ──────────────────────────────────────────────
@router.post("/", response_model=schemas.MessageResponse)
def send_message(
    msg_data: schemas.MessageCreate,
    current_user: models.User = Depends(get_user_from_header),
    db: Session = Depends(get_db)
):
    receiver = db.query(models.User).filter(
        models.User.id == msg_data.receiver_id
    ).first()
    if not receiver:
        raise HTTPException(status_code=404, detail="Receiver not found")

    message = models.Message(
        sender_id=current_user.id,
        receiver_id=msg_data.receiver_id,
        content=msg_data.content
    )
    db.add(message)
    db.commit()
    db.refresh(message)
    return message


# ── GET MY CONVERSATIONS (Inbox list) ──────────────────────────
# NOTE: yeh route "/{other_user_id}" jaisi kisi route se pehle honi chahiye
# (yahan koi conflict nahi hai kyunke get_messages query param leta hai),
# lekin phir bhi isko upar rakha hai taake future mein path-param route
# add ho to yeh accidentally shadow na ho.
@router.get("/conversations", response_model=List[schemas.ConversationResponse])
def get_conversations(
    current_user: models.User = Depends(get_user_from_header),
    db: Session = Depends(get_db)
):
    msgs = db.query(models.Message).filter(
        (models.Message.sender_id == current_user.id) |
        (models.Message.receiver_id == current_user.id)
    ).order_by(models.Message.created_at.desc()).all()

    conversations = {}
    for m in msgs:
        other_id = m.receiver_id if m.sender_id == current_user.id else m.sender_id
        if other_id not in conversations:
            other_user = db.query(models.User).filter(models.User.id == other_id).first()
            unread = sum(
                1 for x in msgs
                if x.sender_id == other_id and x.receiver_id == current_user.id and not x.is_read
            )
            conversations[other_id] = schemas.ConversationResponse(
                other_user_id=other_id,
                other_user_name=other_user.full_name if other_user else "Unknown",
                other_user_phone=other_user.phone if other_user else None,
                last_message=m.content,
                last_message_at=m.created_at,
                unread_count=unread,
            )
    return list(conversations.values())


# ── GET MY MESSAGES ───────────────────────────────────────────
@router.get("/", response_model=List[schemas.MessageResponse])
def get_messages(
    other_user_id: int,
    current_user: models.User = Depends(get_user_from_header),
    db: Session = Depends(get_db)
):
    messages = db.query(models.Message).filter(
        ((models.Message.sender_id == current_user.id) &
         (models.Message.receiver_id == other_user_id)) |
        ((models.Message.sender_id == other_user_id) &
         (models.Message.receiver_id == current_user.id))
    ).order_by(models.Message.created_at.asc()).all()

    # Mark as read
    for msg in messages:
        if msg.receiver_id == current_user.id:
            msg.is_read = True
    db.commit()

    return messages
