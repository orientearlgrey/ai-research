# AI Research Task — Manual Search vs. AI Chat

A Flutter web app used as the participant-facing interface for an online experiment on how people look up product information: by reading manually versus asking an AI assistant, with a secondary manipulation on whether the assistant's language emphasizes price.

## How participants reach it

The app is embedded as an `<iframe>` inside a Qualtrics survey page. Qualtrics randomly assigns each participant to a condition and passes it, along with their Prolific ID, into the iframe via URL query params:

```
https://<app-domain>/?condition=manual&pid=<PROLIFIC_PID>
```

- `condition` — one of `manual`, `chat_default`, `chat_price`
- `pid` — the participant's Prolific ID (also accepted as `PROLIFIC_PID` / `prolific_pid`)
- `sid` — optional Qualtrics response ID, used to key stored data; the app generates one if absent

Task length is designed to be ~1–2 minutes. **Qualtrics' own page timer controls advancement to the next survey page** — the app itself has no internal timer, completion button, or "done" signal to send back. It just renders the task for whatever condition it's told.

## The three conditions

All three share the same visual frame: the left ~2/3–3/4 of the screen shows a static shelf/product image; the remaining right portion shows a phone-mockup frame, inside which the task itself renders — making it look like the participant is using a phone. Chat is text-only but renders markdown (bold, lists) using the *same* rendering widget as the document reader, so the visual style of information doesn't differ across conditions — that's a deliberate control, not an oversight.

- **`manual`** — a markdown document reader. The document contains one "focal" product plus several others, each written in a Google-AI-Mode-search-response style: a bold, scannable product name, followed by body text long enough that actually reading an entry takes about a minute (so the task tests reading comprehension, not just lookup speed). The list is shuffled per participant.
- **`chat_default`** — the same document is handed to an AI assistant as grounding context. The participant asks questions in a chat UI instead of reading the document themselves.
- **`chat_price`** — identical to `chat_default`, except the assistant's system prompt additionally instructs it to make price-related language (budget, affordable, luxury, expensive, cheap, etc.) more salient throughout its responses. This is the experimental manipulation of interest.

## Why the document order is shuffled

If the focal product always sat in the same position (e.g. always first, or alphabetical), the `manual` condition would take a predictable, probably too-short amount of time regardless of document length — undermining the 1–2 minute target and making manual search trivially easy relative to asking the AI. To avoid that:

- The product list is shuffled (not just the focal product's position — the whole list) using a seeded random shuffle.
- The seed is derived deterministically from the participant's Prolific ID, so the same participant always sees the same order (reproducible for analysis) without needing to separately store "what order did we show them."
- This shuffle happens once, client-side, and the resulting document text is reused both for on-screen rendering *and* as the context sent to the AI backend — so the AI conditions and the manual condition are always working from the same shuffled document, generated in exactly one place.

## Data being collected

- **Conversation transcripts** (`chat_default` / `chat_price` only): Prolific ID, condition, and every chat turn (role, content, timestamp).
- **Behavioral events** (all conditions): lightweight timestamped events like session start and document-loaded, mainly so the `manual` condition — which has no chat transcript — still has some timing data to analyze.

## Architecture

```
Participant's browser (inside Qualtrics iframe)
  └─ Flutter web app (static, hosted on Firebase Hosting)
       ├─ manual condition: renders the document entirely client-side, no network calls
       └─ chat conditions: calls a backend endpoint for every message
                │
                ▼
     Cloud Functions (Firebase, holds the AI provider's API key)
       ├─ /chat      → proxies to the AI provider, logs the turn to Firestore, returns the reply
       └─ /logEvent  → logs a behavioral event to Firestore
                │
                ▼
          Firestore (conversation transcripts + event logs)
```

The Flutter app never talks to the AI provider or to Firestore directly — only to these two backend endpoints. That keeps the API key off the client entirely (a Flutter *web* app can't hide secrets — anything client-side is visible in devtools) and means Firestore needs no public-facing security rules, since only the backend (using admin privileges) ever reads or writes it.

The AI assistant isn't doing retrieval-augmented search over a large corpus — the document is short enough (one focal product + a handful of others) that the full text is just included directly in every request as context. No vector database or embedding step is needed.

## Open items to confirm before building

- Exact Qualtrics embedded-data field names for `condition` / Prolific ID, and the iframe snippet to place in the Qualtrics question.
- The real shelf/product image and the real product copy (the document content is currently just a schema, not real text).
- The exact wording of the price-salience system prompt — the version in the implementation plan is a starting point, not pretested language.
- Whether to restrict iframe embedding to the Qualtrics domain specifically (optional hardening; not required for the embed to work).

A more detailed, implementation-level plan (file structure, schemas, library choices) exists alongside this README for when we're ready to start building.
