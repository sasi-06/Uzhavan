# Uzhavan

**Rent farm machines by voice, in your own language.**

A production-grade two-sided marketplace connecting farm machine owners with farmers who need them. Built for low-literacy users with voice-first navigation, multi-language support (Tamil, Telugu, Hindi), and minimal icon-driven UI.

## Architecture

```
uzhavan/
├── backend/         NestJS REST API (PostgreSQL + PostGIS, Redis)
├── mobile/          Flutter app (Android/iOS, offline-capable)
├── admin/           React + Tailwind admin dashboard
├── voice-service/   Rasa NLU + dialog manager (fixed intents)
└── docker-compose.yml
```

## MVP Scope (Phase 1)

- Phone + OTP registration/login
- Machine listing (owner) with photos, pricing, availability
- Geo search by machine type and location
- Booking flow (≤ 3 steps) with UPI / cash-on-pickup
- Escrow-style payment hold until job completion

## Getting Started

### Prerequisites

- Node.js 20+
- Docker & Docker Compose
- Flutter 3.x (for mobile)
- PostgreSQL client (optional)

### 1. Start infrastructure

```bash
cp .env.example .env
docker compose up -d postgres redis
```

### 2. Backend API

```bash
cd backend
npm install
npm run seed
npm run start:dev
```

API available at `http://localhost:3000/api/v1`

### 3. Mobile app

```bash
cd mobile
flutter pub get
flutter run
```

### 4. Admin dashboard

```bash
cd admin
npm install
npm run dev
```

Dashboard at `http://localhost:5173`

## API Overview

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/send-otp` | Send OTP to phone |
| POST | `/api/v1/auth/verify-otp` | Verify OTP, get JWT |
| GET | `/api/v1/machines/search` | Search machines (type, lat, lng, date) |
| POST | `/api/v1/bookings` | Create booking |
| POST | `/api/v1/payments/initiate` | Initiate UPI payment |

## Design Principles

- **Voice-first, not voice-only** — every action reachable by voice AND tap
- **Icon-first navigation** — actions understandable without reading labels
- **Fixed voice intents** — closed intent set for noisy field environments
- **Dual feedback** — every important state communicated via TTS + visual cue
- **One primary action per screen** — max 2-level navigation depth

## Delivery Phases

1. **MVP** — registration, listing, search, booking, payment *(current)*
2. **Voice** — ASR → NLU → dialog manager → TTS pipeline
3. **Accessibility** — full i18n, IVR/SMS fallback flows

## License

Proprietary — All rights reserved.
