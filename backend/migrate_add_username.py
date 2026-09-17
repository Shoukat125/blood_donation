"""
One-time migration: existing `users` table mein `username` column add karta hai.

Yeh zaroori hai kyunke SQLAlchemy ka `create_all()` sirf NAYI tables banata
hai — kisi EXISTING table mein naya column apne aap add nahi karta. Isliye
yeh script raw SQL (ALTER TABLE) chala ke column add karti hai.

Kya karti hai:
  1. `username` column add karti hai (agar pehle se na ho).
  2. Jin existing users ka username khali hai, unko temporarily unka
     email ka pehla hissa (@ se pehle) username bana deti hai
     (jaise shoukatalisukkur@gmail.com -> shoukatalisukkur).
  3. Column ko NOT NULL aur UNIQUE bana deti hai.

Chalane ka tareeka (backend folder ke andar se, venv activate karke):
    $env:DATABASE_URL="<Render wala DATABASE_URL yahan paste karo>"
    python migrate_add_username.py

Safe to re-run — agar column already ban chuka ho to dobara nahi banayegi.
"""
from sqlalchemy import text
from database import engine

with engine.begin() as conn:
    # 1) Column add karo (nullable rakho abhi, taake existing rows na tootien)
    conn.execute(text(
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(50)"
    ))
    print("✅ Step 1: username column add ho gaya (ya pehle se tha).")

    # 2) Jin rows ka username khali hai, unhein email ke pehle hisse se bharo
    conn.execute(text("""
        UPDATE users
        SET username = split_part(email, '@', 1)
        WHERE username IS NULL OR username = ''
    """))
    print("✅ Step 2: purane users ke liye temporary username bhar diya (email ka pehla hissa).")

    # 3) Agar koi duplicate ban gaya ho (rare case), unhe unique banao
    #    id number attach karke — taake unique constraint fail na ho.
    conn.execute(text("""
        UPDATE users u
        SET username = u.username || '_' || u.id
        WHERE EXISTS (
            SELECT 1 FROM users u2
            WHERE u2.username = u.username AND u2.id != u.id
        )
    """))

    # 4) NOT NULL + UNIQUE constraint lagao
    conn.execute(text("ALTER TABLE users ALTER COLUMN username SET NOT NULL"))
    conn.execute(text(
        "CREATE UNIQUE INDEX IF NOT EXISTS ix_users_username ON users (username)"
    ))
    print("✅ Step 3: username column ab NOT NULL aur UNIQUE hai.")

print("\n🎉 Migration complete! Ab purane accounts ka username unka email-prefix hai")
print("   (jaise shoukatalisukkur@gmail.com wale ka username: shoukatalisukkur)")
print("   Login ab isi username se hoga.")
