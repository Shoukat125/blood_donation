from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from typing import Optional, List
import random
import string
from datetime import date

import models
import schemas
from database import get_db
from routers.auth import get_current_user

router = APIRouter(prefix="/api/requests", tags=["Blood Requests"])


def get_user_from_header(authorization: Optional[str] = Header(None), db: Session = Depends(get_db)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Not authenticated")
    token = authorization.split(" ")[1]
    return get_current_user(token, db)


def generate_ref():
    return "REQ-" + "".join(random.choices(string.digits, k=8))


def _attach_donor_info(req: models.BloodRequest, db: Session):
    """Agar request 'Confirmed' hai, jo donor ne accept kiya uska naam/phone
    response mein attach karo (taake requester ko pata chale kaun aa raha hai)."""
    req.donor_name = None
    req.donor_phone = None
    if req.status == "Confirmed":
        accepted = db.query(models.DonorNotification).filter(
            models.DonorNotification.request_id == req.id,
            models.DonorNotification.status == "Accepted"
        ).first()
        if accepted:
            donor = db.query(models.User).filter(models.User.id == accepted.donor_id).first()
            if donor:
                req.donor_name = donor.full_name
                req.donor_phone = donor.phone
    return req


# ── CREATE BLOOD REQUEST ──────────────────────────────────────
@router.post("/", response_model=schemas.BloodRequestResponse)
def create_request(
    request_data: schemas.BloodRequestCreate,
    db: Session = Depends(get_db),
    authorization: Optional[str] = Header(None)
):
    requester_id = None
    if authorization and authorization.startswith("Bearer "):
        try:
            token = authorization.split(" ")[1]
            user = get_current_user(token, db)
            requester_id = user.id
        except:
            pass

    new_request = models.BloodRequest(
        patient_name=request_data.patient_name,
        patient_age=request_data.patient_age,
        patient_gender=request_data.patient_gender,
        blood_type=request_data.blood_type,
        units_needed=request_data.units_needed,
        urgency=request_data.urgency,
        hospital=request_data.hospital,
        city=request_data.city,
        required_by=request_data.required_by,
        requester_id=requester_id,
        ref_number=generate_ref(),
        status="Searching"
    )

    db.add(new_request)
    db.commit()
    db.refresh(new_request)

    # Notify nearby donors with matching blood type
    matching_donors = db.query(models.User).filter(
        models.User.blood_type == request_data.blood_type,
        models.User.is_available == True
    ).all()

    for donor in matching_donors:
        notification = models.DonorNotification(
            request_id=new_request.id,
            donor_id=donor.id,
            status="Pending"
        )
        db.add(notification)

    db.commit()
    return _attach_donor_info(new_request, db)


# ── GET ALL REQUESTS ──────────────────────────────────────────
@router.get("/", response_model=List[schemas.BloodRequestResponse])
def get_requests(
    blood_type: Optional[str] = None,
    urgency: Optional[str] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(models.BloodRequest)

    if blood_type:
        query = query.filter(models.BloodRequest.blood_type == blood_type)
    if urgency:
        query = query.filter(models.BloodRequest.urgency == urgency)
    if status:
        query = query.filter(models.BloodRequest.status == status)

    results = query.order_by(models.BloodRequest.created_at.desc()).all()
    return [_attach_donor_info(r, db) for r in results]


# ── GET MY DONOR NOTIFICATIONS (Pending matches for this donor) ───
# NOTE: yeh route /{request_id} se UPAR honi chahiye, warna FastAPI
# "/notifications/me" ko bhi {request_id} samajh ke match karne ki koshish
# karega (aur int conversion fail hoga / galat route hit hoga).
@router.get("/notifications/me", response_model=List[schemas.DonorNotificationResponse])
def get_my_notifications(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_user_from_header),
):
    notifications = db.query(models.DonorNotification).filter(
        models.DonorNotification.donor_id == current_user.id,
        models.DonorNotification.status == "Pending"
    ).order_by(models.DonorNotification.created_at.desc()).all()

    result = []
    for n in notifications:
        req = db.query(models.BloodRequest).filter(
            models.BloodRequest.id == n.request_id
        ).first()
        # Agar request ka koi aur donor accept kar chuka hai, ya request
        # already complete/cancelled hai, to yeh notification ab relevant
        # nahi hai — donor ko purani/stale request nahi dikhani.
        if not req or req.status != "Searching":
            continue
        n.patient_name = req.patient_name
        n.blood_type = req.blood_type
        n.units_needed = req.units_needed
        n.hospital = req.hospital
        n.urgency = req.urgency
        n.city = req.city
        n.request_status = req.status
        result.append(n)
    return result


# ── ACCEPT / DECLINE A NOTIFICATION ────────────────────────────
@router.put("/notifications/{notification_id}/respond")
def respond_to_notification(
    notification_id: int,
    body: schemas.NotificationRespond,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_user_from_header),
):
    if body.status not in ("Accepted", "Declined"):
        raise HTTPException(status_code=400, detail="status must be 'Accepted' or 'Declined'")

    notification = db.query(models.DonorNotification).filter(
        models.DonorNotification.id == notification_id
    ).first()
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    if notification.donor_id != current_user.id:
        raise HTTPException(status_code=403, detail="Yeh notification tumhari nahi hai")

    req = db.query(models.BloodRequest).filter(
        models.BloodRequest.id == notification.request_id
    ).first()
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")

    if body.status == "Accepted":
        # Race-condition guard: agar request already kisi aur donor ne accept
        # kar li (ya already confirmed/completed ho gayi), to late aane wale
        # donor ko clearly bata do — duplicate "confirmed" donors nahi banne chahiye.
        if req.status != "Searching":
            raise HTTPException(
                status_code=409,
                detail="Yeh request already confirm ho gayi hai — koi aur donor pehle aa gaya."
            )
        notification.status = "Accepted"
        req.status = "Confirmed"

        # Baqi pending notifications (isi request ke liye, baqi donors ko)
        # band kar do — taake doosre donors ko ek closed request na dikhe.
        others = db.query(models.DonorNotification).filter(
            models.DonorNotification.request_id == req.id,
            models.DonorNotification.id != notification.id,
            models.DonorNotification.status == "Pending"
        ).all()
        for o in others:
            o.status = "Declined"
    else:
        notification.status = "Declined"

    db.commit()
    return {"message": "Response saved", "status": notification.status, "request_status": req.status}


# ── GET REQUEST BY ID ─────────────────────────────────────────
@router.get("/{request_id}", response_model=schemas.BloodRequestResponse)
def get_request(request_id: int, db: Session = Depends(get_db)):
    req = db.query(models.BloodRequest).filter(
        models.BloodRequest.id == request_id
    ).first()
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    return _attach_donor_info(req, db)


# ── UPDATE REQUEST STATUS ─────────────────────────────────────
@router.put("/{request_id}/status")
def update_status(
    request_id: int,
    body: schemas.StatusUpdate,
    db: Session = Depends(get_db)
):
    req = db.query(models.BloodRequest).filter(
        models.BloodRequest.id == request_id
    ).first()
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")

    was_completed_already = req.status == "Completed"
    req.status = body.status

    # ✅ FIX: jab request "Completed" mark ho (donor ne actually blood de diya),
    # to jis donor ne is request ko accept kiya tha uski profile stats
    # (total_donations, lives_saved, last_donation) automatic update karo.
    # was_completed_already guard duplicate/double-counting rokta hai agar
    # koi status ko dobara "Completed" pe set kare.
    if body.status == "Completed" and not was_completed_already:
        accepted = db.query(models.DonorNotification).filter(
            models.DonorNotification.request_id == req.id,
            models.DonorNotification.status == "Accepted"
        ).first()
        if accepted:
            donor = db.query(models.User).filter(
                models.User.id == accepted.donor_id
            ).first()
            if donor:
                donor.total_donations = (donor.total_donations or 0) + 1
                donor.lives_saved = (donor.lives_saved or 0) + 1
                donor.last_donation = date.today().isoformat()

    db.commit()
    return {"message": "Status updated", "status": body.status}
