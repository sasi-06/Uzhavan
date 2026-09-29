# Uzhavan — Firebase Migration Plan

## Goal
Replace **PostgreSQL + Redis + Docker** with **Firebase** (no Docker required).

## Architecture (after migration)

```
Flutter App  ──REST──▶  NestJS API  ──▶  Firestore (database)
                              │              Firebase Auth (optional Phase 2)
                              └────────────▶ Firebase Storage (photos)
```

Local dev uses **Firebase Emulator Suite** (runs via Node, no Docker).

## Firebase services mapping

| Old (removed)        | New (Firebase)                          |
|----------------------|-----------------------------------------|
| PostgreSQL + TypeORM | **Cloud Firestore**                     |
| Redis (OTP cache)    | Firestore `otps` collection + TTL field |
| Redis (booking lock) | **Firestore transactions**              |
| AWS S3               | **Firebase Storage** (stub for photos)  |
| Docker Compose       | **Removed** — use `firebase emulators`  |

## Firestore collections

| Collection      | Purpose                          |
|-----------------|----------------------------------|
| `users`         | Farmers, owners, admins          |
| `machines`      | Machine listings + geo fields    |
| `availability`  | Blocked date ranges              |
| `bookings`      | Rental bookings                  |
| `payments`      | UPI / cash payments              |
| `otps`          | Phone OTP (dev + prod SMS later) |

## Implementation steps

1. Add `firebase/` config + Firestore security rules
2. Add `FirebaseModule` (Admin SDK) to NestJS backend
3. Replace TypeORM repositories with Firestore services
4. Remove Redis, PostgreSQL, Docker dependencies
5. Update seed script to write to Firestore emulator
6. Update `.env.example` and README
7. Run: emulators → seed → backend

## What stays the same

- Flutter app keeps calling the same REST API (`/api/v1/...`)
- JWT auth flow unchanged (OTP stored in Firestore instead of Redis)
- All MVP endpoints preserved
