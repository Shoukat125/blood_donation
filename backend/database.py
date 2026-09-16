import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

# ── PostgreSQL (local pgAdmin database: blood_db) ───────────────
# .env file se DATABASE_URL uthata hai. Agar .env mein na mile,
# to neeche wala local default use hota hai (aapka pgAdmin setup).
SQLALCHEMY_DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:Admin%40123@localhost:5432/blood_db"
)

# PostgreSQL ke liye connect_args ki zaroorat nahi (wo sirf SQLite ke
# liye thi). pool_pre_ping=True lagane se connection auto-recover ho
# jata hai agar laptop sleep se wapas aaye ya connection drop ho jaye —
# 4GB RAM machine pe restart baar baar avoid karne mein madad karta hai.
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    pool_pre_ping=True,
    pool_size=3,        # kam RAM machine ke liye chhoti connection pool
    max_overflow=2,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
