"""
Purane test data (users, blood requests, notifications, messages) ko
Render database se saaf karta hai. `hospitals` table ko haath nahi lagata.

Chalane ka tareeka (backend folder ke andar se, venv activate karke):
    $env:DATABASE_URL="<Render wala DATABASE_URL>"
    python clear_test_data.py
"""
from sqlalchemy import text
from database import engine

# ✅ SAFETY CHECK: delete karne se pehle confirm karo kaunsa database
# target ho raha hai — taake galti se LOCAL database delete na ho.
target_url = engine.url.render_as_string(hide_password=True)
print(f"\n⚠️  Yeh script is database ko target kar rahi hai:\n    {target_url}\n")

if "localhost" in target_url or "127.0.0.1" in target_url:
    print("❌ Yeh LOCAL database hai, Render wala nahi!")
    print("   Pehle terminal mein $env:DATABASE_URL set karo (Render wala URL),")
    print("   phir isi terminal mein dobara yeh script chalao. Rok raha hoon.")
    raise SystemExit(1)

confirm = input("Yeh sahi (Render) database hai? Delete continue karne ke liye 'yes' likho: ")
if confirm.strip().lower() != "yes":
    print("Cancel kar diya. Kuch delete nahi hua.")
    raise SystemExit(0)

with engine.begin() as conn:
    result1 = conn.execute(text("DELETE FROM messages"))
    print(f"✅ messages se {result1.rowcount} row(s) delete hui.")

    result2 = conn.execute(text("DELETE FROM donor_notifications"))
    print(f"✅ donor_notifications se {result2.rowcount} row(s) delete hui.")

    result3 = conn.execute(text("DELETE FROM blood_requests"))
    print(f"✅ blood_requests se {result3.rowcount} row(s) delete hui.")

    result4 = conn.execute(text("DELETE FROM users"))
    print(f"✅ users se {result4.rowcount} row(s) delete hui.")

print("\n🎉 Saara purana test data saaf ho gaya. Hospitals table waisi hi hai.")
print("   Ab aap bilkul fresh accounts register kar sakte hain (username ke sath).")
