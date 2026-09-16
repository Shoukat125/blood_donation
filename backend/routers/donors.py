from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from typing import Optional, List

import models
import schemas
from database import get_db
from routers.auth import get_current_user

router = APIRouter(prefix="/api/donors", tags=["Donors"])


def get_user_from_header(authorization: Optional[str] = Header(None), db: Session = Depends(get_db)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Not authenticated")
    token = authorization.split(" ")[1]
    return get_current_user(token, db)


# ── GET ALL DONORS / SEARCH ───────────────────────────────────
@router.get("/", response_model=List[schemas.UserResponse])
def get_donors(
    blood_type: Optional[str] = None,
    city: Optional[str] = None,
    available_only: bool = True,
    db: Session = Depends(get_db)
):
    query = db.query(models.User)

    if available_only:
        query = query.filter(models.User.is_available == True)

    if blood_type:
        query = query.filter(models.User.blood_type == blood_type)

    if city:
        query = query.filter(models.User.city.ilike(f"%{city}%"))

    donors = query.all()
    return donors


# ── GET DONOR BY ID ───────────────────────────────────────────
@router.get("/{donor_id}", response_model=schemas.UserResponse)
def get_donor(donor_id: int, db: Session = Depends(get_db)):
    donor = db.query(models.User).filter(models.User.id == donor_id).first()
    if not donor:
        raise HTTPException(status_code=404, detail="Donor not found")
    return donor


# ── GET MY PROFILE ────────────────────────────────────────────
@router.get("/me/profile", response_model=schemas.UserResponse)
def get_my_profile(current_user: models.User = Depends(get_user_from_header)):
    return current_user


# ── UPDATE MY PROFILE ─────────────────────────────────────────
@router.put("/me/profile", response_model=schemas.UserResponse)
def update_profile(
    update_data: schemas.UserUpdate,
    current_user: models.User = Depends(get_user_from_header),
    db: Session = Depends(get_db)
):
    for field, value in update_data.model_dump(exclude_unset=True).items():
        setattr(current_user, field, value)

    db.commit()
    db.refresh(current_user)
    return current_user
