from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime


# ── AUTH SCHEMAS ──────────────────────────────────────────────
class UserRegister(BaseModel):
    full_name: str
    username: str
    email: str
    phone: str
    password: str
    blood_type: str
    age: Optional[int] = None
    gender: Optional[str] = None
    city: Optional[str] = None
    last_donation: Optional[str] = None


class UserLogin(BaseModel):
    username: str
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    email: Optional[str] = None


# ── USER / DONOR SCHEMAS ──────────────────────────────────────
class UserResponse(BaseModel):
    id: int
    full_name: str
    username: str
    email: str
    phone: str
    blood_type: str
    age: Optional[int]
    gender: Optional[str]
    city: Optional[str]
    is_available: bool
    last_donation: Optional[str]
    total_donations: int
    lives_saved: int
    rating: float
    is_verified: bool
    max_distance: int
    created_at: datetime

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    city: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    blood_type: Optional[str] = None
    is_available: Optional[bool] = None
    max_distance: Optional[int] = None
    notify_all_types: Optional[bool] = None
    last_donation: Optional[str] = None


class ChangePassword(BaseModel):
    current_password: str
    new_password: str


class ForgotPasswordRequest(BaseModel):
    email: str


class ResetPasswordRequest(BaseModel):
    email: str
    code: str
    new_password: str


class StatusUpdate(BaseModel):
    status: str


# ── DONOR NOTIFICATION SCHEMAS ─────────────────────────────────
class DonorNotificationResponse(BaseModel):
    id: int
    request_id: int
    status: str
    created_at: datetime
    # Request snapshot so the donor can see what they're being asked to help with
    patient_name: Optional[str] = None
    blood_type: Optional[str] = None
    units_needed: Optional[int] = None
    hospital: Optional[str] = None
    urgency: Optional[str] = None
    city: Optional[str] = None
    request_status: Optional[str] = None

    class Config:
        from_attributes = True


class NotificationRespond(BaseModel):
    status: str  # "Accepted" or "Declined"


# ── BLOOD REQUEST SCHEMAS ─────────────────────────────────────
class BloodRequestCreate(BaseModel):
    patient_name: str
    patient_age: Optional[int] = None
    patient_gender: Optional[str] = None
    blood_type: str
    units_needed: int = 1
    urgency: str = "Normal"
    hospital: str
    city: Optional[str] = None
    required_by: Optional[str] = None


class BloodRequestResponse(BaseModel):
    id: int
    patient_name: str
    patient_age: Optional[int]
    patient_gender: Optional[str]
    blood_type: str
    units_needed: int
    urgency: str
    hospital: str
    city: Optional[str]
    status: str
    ref_number: str
    required_by: Optional[str]
    created_at: datetime
    # Populated once a donor accepts (status == "Confirmed")
    donor_name: Optional[str] = None
    donor_phone: Optional[str] = None

    class Config:
        from_attributes = True


# ── MESSAGE SCHEMAS ───────────────────────────────────────────
class MessageCreate(BaseModel):
    receiver_id: int
    content: str


class MessageResponse(BaseModel):
    id: int
    sender_id: int
    receiver_id: int
    content: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True


class ConversationResponse(BaseModel):
    other_user_id: int
    other_user_name: str
    other_user_phone: Optional[str] = None
    last_message: str
    last_message_at: datetime
    unread_count: int


# ── HOSPITAL SCHEMAS ──────────────────────────────────────────
class HospitalResponse(BaseModel):
    id: int
    name: str
    city: str
    address: Optional[str]
    distance_km: Optional[float]

    class Config:
        from_attributes = True
