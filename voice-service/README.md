# Uzhavan Voice Service

Fixed-intent voice pipeline: **ASR → NLU → Dialog Manager → Business Logic API → TTS**

## Architecture

```
User speech
    ↓
Bhashini ASR (primary) / Google STT (fallback)
    ↓
Rasa NLU — fixed intents only
    ↓
Dialog Manager — confirmation loop before actions
    ↓
Uzhavan Backend API (REST)
    ↓
Bhashini TTS → spoken response
```

## Core Intents (Phase 2)

| Intent | Slots |
|--------|-------|
| `search_machine` | machine_type, location, date |
| `book_machine` | machine_id, date, duration_or_area, operator_included |
| `check_booking_status` | — |
| `cancel_booking` | booking_id |
| `contact_owner` | booking_id |
| `rate_owner` | rating_value, comment_optional |
| `list_my_machine` | machine_type, price, availability |
| `check_earnings` | — |

## Setup (coming in Phase 2)

```bash
cd voice-service
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
rasa train
rasa run --enable-api --port 5005
```

## Confirmation Rule

Before any booking, cancellation, or payment action, the dialog manager reads back parsed intent + slots in the user's language and requires explicit voice or single-tap confirmation.

## Fallback Rule

If ASR fails twice on the same task, the mobile app drops to simplified icon-based manual UI for that task.
