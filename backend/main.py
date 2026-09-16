from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os

import models
from database import engine
from routers import auth, donors, requests, messages, hospitals

# ── Create all database tables ────────────────────────────────
models.Base.metadata.create_all(bind=engine)

# ✅ FIX (#4): agar production mein SECRET_KEY env var set nahi ki gayi,
# yeh terminal pe loud warning dega — taake galti se default secret ke
# saath deploy na ho jaye.
if not os.getenv("SECRET_KEY"):
    print("⚠️  WARNING: SECRET_KEY env var set nahi hai — abhi default/fallback "
          "secret use ho raha hai. Production mein yeh security risk hai. "
          "backend/.env.example dekho.")

# ── FastAPI App ───────────────────────────────────────────────
app = FastAPI(
    title="Blood Donation API",
    description="Blood Donation App ka Backend API",
    version="1.0.0"
)

# ── CORS — Flutter app se connect karne ke liye ───────────────
# ⚠️ NOTE: allow_origins=["*"] abhi early testing ke liye theek hai
# (local dev, koi bhi device se test karna aasan hoga). Lekin Play
# Store launch se PEHLE isko apne deployed backend ke real frontend
# origin(s) tak restrict kar dena — warna koi bhi website ye API
# directly call kar sakti hai. Example (production mein):
#   allow_origins=["https://yourapp.com"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────
app.include_router(auth.router)
app.include_router(donors.router)
app.include_router(requests.router)
app.include_router(messages.router)
app.include_router(hospitals.router)


# ── Root endpoint ─────────────────────────────────────────────
@app.get("/")
def root():
    return {
        "message": "🩸 Blood Donation API is Running!",
        "version": "1.0.0",
        "docs": "http://localhost:8000/docs"
    }


# ── Health check ──────────────────────────────────────────────
@app.get("/health")
def health():
    return {"status": "OK"}
