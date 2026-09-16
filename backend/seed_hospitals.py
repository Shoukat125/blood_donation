"""
One-time script to add starter hospitals to the database.
Run this once after the new `hospitals` table is created:

    python seed_hospitals.py

Safe to re-run — it skips hospitals that already exist (by name).

Coverage: major public/private hospitals across Sindh (city-wise). Add more
cities/hospitals here later when expanding to other provinces — just add
new dicts to the HOSPITALS list below, format stays the same.
"""
import models
from database import SessionLocal, engine

models.Base.metadata.create_all(bind=engine)

# distance_km intentionally left out (None) — it was a fake placeholder
# number before; a real value needs Google Maps / user-location integration
# (see models.py comment on Hospital.distance_km). Showing a fake distance
# is misleading, so we leave it blank until that feature is built.
HOSPITALS = [
    # ── Karachi ──────────────────────────────────────────────
    {"name": "Jinnah Postgraduate Medical Centre (JPMC)", "city": "Karachi", "address": "Rafiqui Shaheed Rd, Karachi"},
    {"name": "Civil Hospital Karachi", "city": "Karachi", "address": "Baba-e-Urdu Rd, Karachi"},
    {"name": "Aga Khan University Hospital", "city": "Karachi", "address": "Stadium Rd, Karachi"},
    {"name": "Liaquat National Hospital", "city": "Karachi", "address": "Stadium Rd, Karachi"},
    {"name": "South City Hospital", "city": "Karachi", "address": "Shahrah-e-Faisal, Karachi"},
    {"name": "National Institute of Cardiovascular Diseases (NICVD)", "city": "Karachi", "address": "Rafiqui Shaheed Rd, Karachi"},
    {"name": "Indus Hospital", "city": "Karachi", "address": "Korangi Crossing, Karachi"},
    {"name": "Sindh Government Hospital Liaquatabad", "city": "Karachi", "address": "Liaquatabad, Karachi"},

    # ── Hyderabad ────────────────────────────────────────────
    {"name": "Liaquat University Hospital (LUH)", "city": "Hyderabad", "address": "Hyderabad"},
    {"name": "Civil Hospital Hyderabad", "city": "Hyderabad", "address": "Hyderabad"},

    # ── Sukkur ───────────────────────────────────────────────
    {"name": "Ghulam Muhammad Mahar Medical College Hospital", "city": "Sukkur", "address": "Sukkur"},
    {"name": "Civil Hospital Sukkur", "city": "Sukkur", "address": "Sukkur"},

    # ── Larkana ──────────────────────────────────────────────
    {"name": "Chandka Medical College Hospital", "city": "Larkana", "address": "Larkana"},
    {"name": "Civil Hospital Larkana", "city": "Larkana", "address": "Larkana"},

    # ── Nawabshah / Shaheed Benazirabad ─────────────────────
    {"name": "Peoples Medical College Hospital", "city": "Nawabshah", "address": "Nawabshah"},

    # ── Mirpurkhas ───────────────────────────────────────────
    {"name": "Civil Hospital Mirpurkhas", "city": "Mirpurkhas", "address": "Mirpurkhas"},

    # ── Jacobabad ────────────────────────────────────────────
    {"name": "Civil Hospital Jacobabad", "city": "Jacobabad", "address": "Jacobabad"},

    # ── Khairpur ─────────────────────────────────────────────
    {"name": "Civil Hospital Khairpur", "city": "Khairpur", "address": "Khairpur"},

    # ── Dadu ─────────────────────────────────────────────────
    {"name": "Civil Hospital Dadu", "city": "Dadu", "address": "Dadu"},

    # ── Thatta ───────────────────────────────────────────────
    {"name": "Civil Hospital Thatta", "city": "Thatta", "address": "Thatta"},

    # ── Shikarpur ────────────────────────────────────────────
    {"name": "Civil Hospital Shikarpur", "city": "Shikarpur", "address": "Shikarpur"},

    # ── Badin ────────────────────────────────────────────────
    {"name": "Civil Hospital Badin", "city": "Badin", "address": "Badin"},

    # ── Umerkot ──────────────────────────────────────────────
    {"name": "Civil Hospital Umerkot", "city": "Umerkot", "address": "Umerkot"},

    # ── Tando Adam ───────────────────────────────────────────
    {"name": "Taluka Hospital Tando Adam", "city": "Tando Adam", "address": "Tando Adam"},

    # ── Tando Allahyar ───────────────────────────────────────
    {"name": "Civil Hospital Tando Allahyar", "city": "Tando Allahyar", "address": "Tando Allahyar"},
]

db = SessionLocal()
try:
    added = 0
    for h in HOSPITALS:
        exists = db.query(models.Hospital).filter(models.Hospital.name == h["name"]).first()
        if exists:
            continue
        db.add(models.Hospital(**h))
        added += 1
    db.commit()
    print(f"Done. Added {added} new hospital(s).")
finally:
    db.close()
