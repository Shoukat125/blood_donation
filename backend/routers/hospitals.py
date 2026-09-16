from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional, List

import models
import schemas
from database import get_db

router = APIRouter(prefix="/api/hospitals", tags=["Hospitals"])


# ── GET ALL HOSPITALS (optionally filter by city) ─────────────
@router.get("/", response_model=List[schemas.HospitalResponse])
def get_hospitals(
    city: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(models.Hospital)

    if city:
        query = query.filter(models.Hospital.city.ilike(f"%{city}%"))

    return query.order_by(models.Hospital.name).all()


# ── GET HOSPITAL BY ID ─────────────────────────────────────────
@router.get("/{hospital_id}", response_model=schemas.HospitalResponse)
def get_hospital(hospital_id: int, db: Session = Depends(get_db)):
    hospital = db.query(models.Hospital).filter(models.Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(status_code=404, detail="Hospital not found")
    return hospital
