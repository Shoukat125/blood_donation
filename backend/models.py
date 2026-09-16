from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, Text
from sqlalchemy.sql import func
from database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    phone = Column(String(20), nullable=False)
    password_hash = Column(String(255), nullable=False)
    blood_type = Column(String(5), nullable=False)
    age = Column(Integer)
    gender = Column(String(10))
    city = Column(String(100))
    is_available = Column(Boolean, default=True)
    last_donation = Column(String(20), nullable=True)
    total_donations = Column(Integer, default=0)
    lives_saved = Column(Integer, default=0)
    rating = Column(Float, default=0.0)
    is_verified = Column(Boolean, default=False)
    max_distance = Column(Integer, default=10)
    notify_all_types = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class BloodRequest(Base):
    __tablename__ = "blood_requests"

    id = Column(Integer, primary_key=True, index=True)
    patient_name = Column(String(100), nullable=False)
    patient_age = Column(Integer)
    patient_gender = Column(String(10))
    blood_type = Column(String(5), nullable=False)
    units_needed = Column(Integer, default=1)
    urgency = Column(String(20), default="Normal")  # Normal, Urgent, Critical
    hospital = Column(String(200), nullable=False)
    city = Column(String(100))
    status = Column(String(30), default="Searching")  # Searching, Confirmed, Completed
    requester_id = Column(Integer, nullable=True)
    ref_number = Column(String(50), unique=True)
    required_by = Column(String(50), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class DonorNotification(Base):
    __tablename__ = "donor_notifications"

    id = Column(Integer, primary_key=True, index=True)
    request_id = Column(Integer, nullable=False)
    donor_id = Column(Integer, nullable=False)
    status = Column(String(20), default="Pending")  # Pending, Accepted, Declined
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class Message(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, nullable=False)
    receiver_id = Column(Integer, nullable=False)
    content = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class Hospital(Base):
    __tablename__ = "hospitals"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    city = Column(String(100), nullable=False)
    address = Column(String(300), nullable=True)
    distance_km = Column(Float, nullable=True)  # straight-line placeholder until real Maps integration (#20)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
