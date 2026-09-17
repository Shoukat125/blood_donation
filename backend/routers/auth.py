from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import Optional
import os
import smtplib
from email.mime.text import MIMEText
from jose import JWTError, jwt
from passlib.context import CryptContext

import models
import schemas
from database import get_db

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

# ── CONFIG ────────────────────────────────────────────────────
# ✅ FIX (#4): SECRET_KEY ab hardcoded nahi hai — environment variable se aati hai.
# Production (Render/Railway/etc) mein dashboard pe SECRET_KEY env var set karo.
# Local dev ke liye agar env var set nahi hai, ek default fallback chalta hai
# (lekin yeh fallback PRODUCTION mein kabhi use nahi hona chahiye).
SECRET_KEY = os.getenv("SECRET_KEY", "blood_donation_secret_key_2026")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 days

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ── HELPER FUNCTIONS ──────────────────────────────────────────
def hash_password(password: str):
    return pwd_context.hash(password[:72])


def verify_password(plain_password: str, hashed_password: str):
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def get_current_user(token: str, db: Session):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("sub")
        if email is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        user = db.query(models.User).filter(models.User.email == email).first()
        if user is None:
            raise HTTPException(status_code=401, detail="User not found")
        return user
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")


# ── ROUTES ────────────────────────────────────────────────────
@router.post("/register", response_model=schemas.UserResponse)
def register(user_data: schemas.UserRegister, db: Session = Depends(get_db)):
    # ✅ FIX: email hamesha lowercase karke save/compare karo, taake
    # "Test@Gmail.com" aur "test@gmail.com" alag accounts na banein
    # aur login case-mismatch ki wajah se fail na ho.
    email_normalized = user_data.email.strip().lower()
    username_normalized = user_data.username.strip().lower()

    if not username_normalized:
        raise HTTPException(status_code=400, detail="Username khali nahi ho sakta")

    # Check if email already exists
    existing_email = db.query(models.User).filter(
        models.User.email == email_normalized
    ).first()
    if existing_email:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )

    # Check if username already exists
    existing_username = db.query(models.User).filter(
        models.User.username == username_normalized
    ).first()
    if existing_username:
        raise HTTPException(
            status_code=400,
            detail="Yeh username pehle se liya ja chuka hai, koi aur try karein"
        )

    # Create new user
    new_user = models.User(
        full_name=user_data.full_name,
        username=username_normalized,
        email=email_normalized,
        phone=user_data.phone,
        password_hash=hash_password(user_data.password),
        blood_type=user_data.blood_type,
        age=user_data.age,
        gender=user_data.gender,
        city=user_data.city,
        last_donation=user_data.last_donation,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


@router.post("/login", response_model=schemas.Token)
def login(user_data: schemas.UserLogin, db: Session = Depends(get_db)):
    # Login ab username se hota hai (email se nahi) — lowercase/trim
    # karke compare karo taake case-mismatch se login fail na ho.
    username_normalized = user_data.username.strip().lower()
    user = db.query(models.User).filter(
        models.User.username == username_normalized
    ).first()

    if not user or not verify_password(user_data.password, user.password_hash):
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    access_token = create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}


# ── CHANGE PASSWORD — Issue #17 ──────────────────────────────
def get_user_from_header(authorization: Optional[str] = Header(None), db: Session = Depends(get_db)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Not authenticated")
    token = authorization.split(" ")[1]
    return get_current_user(token, db)


@router.post("/change-password")
def change_password(
    data: schemas.ChangePassword,
    current_user: models.User = Depends(get_user_from_header),
    db: Session = Depends(get_db)
):
    if not verify_password(data.current_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Current password is incorrect")

    if len(data.new_password) < 6:
        raise HTTPException(status_code=400, detail="New password must be at least 6 characters")

    current_user.password_hash = hash_password(data.new_password)
    db.commit()
    return {"message": "Password updated successfully"}


# ── FORGOT & RESET PASSWORD ───────────────────────────────────
# In-memory store for reset codes: {email: {"code": "123456", "expires_at": datetime}}
# In production, this can be backed by Redis or an email provider like SendGrid/SES.
_reset_codes = {}

import random


def send_reset_email(to_email: str, code: str) -> bool:
    """
    Gmail SMTP ke zariye reset code email karta hai.
    Render Environment mein yeh 2 variables set hone chahiye:
      SMTP_EMAIL         -> Gmail address jis se bhejna hai
      SMTP_APP_PASSWORD  -> Gmail "App Password" (normal Gmail password NAHI)
    Agar yeh set nahi hain, ya bhejte waqt koi error aaye, function False
    return karta hai aur code sirf Render logs mein print hota hai (backup).
    """
    smtp_email = os.getenv("SMTP_EMAIL")
    smtp_password = os.getenv("SMTP_APP_PASSWORD")

    if not smtp_email or not smtp_password:
        print("⚠️  SMTP_EMAIL / SMTP_APP_PASSWORD env vars set nahi hain — "
              "email nahi bheja gaya, code sirf logs mein hai.")
        return False

    body = (
        f"Aapka Blood Donation App password reset code hai: {code}\n\n"
        f"Yeh code 15 minute ke liye valid hai. Agar aapne yeh request nahi ki, "
        f"is email ko ignore kar dein."
    )
    msg = MIMEText(body)
    msg["Subject"] = "Blood Donation App - Password Reset Code"
    msg["From"] = smtp_email
    msg["To"] = to_email

    try:
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(smtp_email, smtp_password)
            server.sendmail(smtp_email, [to_email], msg.as_string())
        return True
    except Exception as e:
        print(f"⚠️  Reset email bhejne mein error: {e}")
        return False

@router.post("/forgot-password")
def forgot_password(data: schemas.ForgotPasswordRequest, db: Session = Depends(get_db)):
    email = data.email.strip().lower()
    user = db.query(models.User).filter(models.User.email == email).first()

    # ✅ SECURITY FIX: agar account exist nahi karta to bhi wohi generic
    # success message return karte hain jo real account ke liye hota hai.
    # Warna response se pata chal jata hai ke ye email registered hai ya
    # nahi (user enumeration attack) — koi bhi is se registered emails
    # ki list bana sakta tha.
    generic_response = {
        "message": f"Agar {email} par account maujood hai, reset code bhej diya gaya hai",
        "email": email
    }

    if not user:
        return generic_response

    # Generate 6-digit random code
    code = f"{random.randint(100000, 999999)}"
    expires_at = datetime.utcnow() + timedelta(minutes=15)
    _reset_codes[email] = {
        "code": code,
        "expires_at": expires_at
    }

    # Console log for local dev / backup (agar email fail ho jaye to yahan se
    # bhi code dekh sakte ho — Render Dashboard → Logs)
    print(f"\n==========================================")
    print(f"🔑 PASSWORD RESET CODE FOR {email}: {code}")
    print(f"Valid for 15 minutes until {expires_at}")
    print(f"==========================================\n")

    # Asal email bhejne ki koshish karo
    send_reset_email(email, code)

    return generic_response


@router.post("/reset-password")
def reset_password(data: schemas.ResetPasswordRequest, db: Session = Depends(get_db)):
    email = data.email.strip().lower()
    code_info = _reset_codes.get(email)

    if not code_info:
        raise HTTPException(status_code=400, detail="Invalid ya expired reset request. Dobara try karein.")

    if datetime.utcnow() > code_info["expires_at"]:
        _reset_codes.pop(email, None)
        raise HTTPException(status_code=400, detail="Reset code expire ho chuka hai. Naya code request karein.")

    if code_info["code"] != data.code.strip():
        raise HTTPException(status_code=400, detail="Ghalat reset code enter kiya hai.")

    if len(data.new_password) < 6:
        raise HTTPException(status_code=400, detail="New password kam az kam 6 characters ka hona chahiye")

    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User account nahi mila")

    user.password_hash = hash_password(data.new_password)
    db.commit()

    # Clear used reset code
    _reset_codes.pop(email, None)

    return {"message": "Password kamyabi se update ho gaya hai. Ab aap login kar sakte hain."}
