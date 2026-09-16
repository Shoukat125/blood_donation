# 🩸 Blood Donation App — Flutter

Saari 7 screens ka complete Flutter code.

## Screens
1. ✅ Dashboard
2. ✅ Donor Registration
3. ✅ Donor Search
4. ✅ Request Blood
5. ✅ Confirmation & Tracking
6. ✅ Donor Profile
7. ✅ My Profile / Edit

## Setup Instructions

### Step 1 — Flutter Install (agar pehle se nahi)
```
https://docs.flutter.dev/get-started/install
```

### Step 2 — Project Chalao
```bash
# Folder mein jao
cd blood_donation_app

# Dependencies install karo
flutter pub get

# App chalao (emulator ya phone)
flutter run
```

### Step 3 — Real Device Par
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios
```

## Project Structure
```
lib/
  main.dart     ← Saari 7 screens ek hi file mein
pubspec.yaml    ← Dependencies
```

## Color Theme
- Primary Red:  #C0141A
- Dark BG:      #0A0A0A
- Card:         #161616

## Features
- Dark red theme — bilkul screenshots jaisi
- Bottom navigation with FAB
- Interactive blood type selector
- Units counter (+/-)
- Hospital selection
- Urgency level toggle
- Availability toggle (My Profile)
- All 7 screens with navigation
