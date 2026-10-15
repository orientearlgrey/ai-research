# AI Research Task — Manual Search vs. AI Chat

A Flutter web app used as the participant-facing interface for an online experiment on how people look up product information: by reading manually versus asking an AI assistant, with a secondary manipulation on whether the assistant's language emphasizes price.

## How participants reach it

The app is embedded as an `<iframe>` inside a Qualtrics survey page. Qualtrics randomly assigns each participant to a condition and passes it, along with their Prolific ID, into the iframe via URL query params:

```
https://<app-domain>/?stim=36bde6&pid=<PROLIFIC_PID>&sid=<RESPONSE_ID>&psid=<PROLIFIC_SESSION_ID>&study=<PROLIFIC_STUDY_ID>
```

- `stim` — an opaque stimulus code, so the condition name never appears in the iframe URL. It is the first 6 hex characters of `sha256(<condition name>)`:

  | Condition | `stim` |
  | --- | --- |
  | `manual` | `36bde6` |
  | `chat_default` | `fbd736` |
  | `chat_price` | `64e213` |

  Qualtrics just stores these literal strings as embedded data; it never computes a hash. This is obfuscation, not secrecy: with only three possible values, anyone who guesses the names can reproduce the hashes. The mapping is pinned in `test/config/session_config_test.dart`, and the Cloud Functions backend must use the same one.
- `pid` — the participant's Prolific ID (also accepted as `PROLIFIC_PID` / `prolific_pid`)
- `sid` — optional Qualtrics `ResponseID`, the key that joins stored data to survey responses; the app generates one if absent
- `psid` — optional Prolific `SESSION_ID` (one per attempt), for reconciling returned or re-entered sessions
- `study` — optional Prolific `STUDY_ID`, so one backend can serve multiple studies

Empty values (Qualtrics pipes an unset embedded-data field as an empty string) are treated as not provided. `PROLIFIC_PID`, `STUDY_ID` and `SESSION_ID` only reach the iframe if they are declared as Embedded Data at the top of the Qualtrics Survey Flow, before the Randomizer.

Task length is designed to be ~1–2 minutes. **Qualtrics' own page timer controls advancement to the next survey page** — the app itself has no internal timer, completion button, or "done" signal to send back. It just renders the task for whatever condition it's told.

## Embedding in Qualtrics

Place this in the question's HTML view. The `${e://Field/...}` pieces are Qualtrics piped text, filled from Embedded Data:

```html
<iframe src="https://<app-domain>/?stim=${e://Field/stim}&pid=${e://Field/PROLIFIC_PID}&sid=${e://Field/ResponseID}&psid=${e://Field/SESSION_ID}&study=${e://Field/STUDY_ID}"
        style="width:100%; height:65vh; border:0; display:block"></iframe>
```

- **Set `stim` per branch.** A Randomizer in the Survey Flow assigns one of the three `stim` codes above as Embedded Data.
- **Don't break the iframe out of the survey column.** A full-viewport-width wrapper (`100vw` plus negative margins) looks tempting, but Qualtrics' container clips it and adds a horizontal scrollbar. The app is built to fit whatever width the column gives it.
- **Height drives the layout.** The phone is sized from the iframe's height (`65vh` is the value settled on after testing in Qualtrics), so changing the height rescales the phone.
- **Framing is restricted.** The app only allows embedding from `https://lse.eu.qualtrics.com` (plus localhost for testing); see [Hosting and deployment](#hosting-and-deployment).

## The three conditions

All three share the same visual frame: a static shelf image fills the left side of the screen, and a phone-mockup frame sits on the right, inside which the task itself renders — making it look like the participant is using a phone. Chat is text-only but renders markdown (bold, lists) using the *same* rendering widget as the document reader, so the visual style of information doesn't differ across conditions — that's a deliberate control, not an oversight.

- **Shelf image.** Identical for every participant and condition. It is an identity prime: it shows only the endorser ("Chosen by Kim Go-Eun") and the price, with almost no product information. That way, the material information about the product's attributes can only come from the document reader or the AI chat, never from the image.
- **Phone frame sizing.** The frame takes its height from the available space, and its width is 1.03× that of a standard 9:19.5 phone at that height. It is capped at 55% of the viewport width, shrinking proportionally in a tall, narrow viewport so the shelf image always keeps room. The shelf panel takes whatever width is left; there is no fixed split.
- **Content zoom.** Everything inside the phone screen is rendered at 90% (`PhoneMockupFrame.contentZoom`), like browser zoom, so more text fits. Text, padding and bullets scale together, and it applies to every condition.

- **`manual`** — a markdown document reader. The document contains one "focal" product plus several others, each written in a Google-AI-Mode-search-response style: a bold, scannable product name, followed by body text long enough that actually reading an entry takes about a minute (so the task tests reading comprehension, not just lookup speed). The list is shuffled per participant. Each product is its own markdown section with a header, separated from the next by whitespace (`DocumentReaderView.sectionSpacing`, 80px) rather than a divider line. Two inline tags from the source content get custom styling: `<mark>…</mark>` renders as a highlighted key claim, and `<span class="dotted">…</span>` as a dotted-underlined product name. `buildDocumentMarkdown` still produces the single `---`-joined document string, which is what the chat backend will receive as context.
- **`chat_default`** — the same document is handed to an AI assistant as grounding context. The participant asks questions in a chat UI instead of reading the document themselves.
- **`chat_price`** — identical to `chat_default`, except the assistant's system prompt additionally instructs it to make price-related language (budget, affordable, luxury, expensive, cheap, etc.) more salient throughout its responses. This is the experimental manipulation of interest.

## Stimulus content

The document is `assets/content/products.json` (10 products) and the shelf image is `assets/images/shelf_image.png`. Both are bundled into the app at build time.

- **La Roche-Posay was removed.** Its entry was replaced with Avène Cicalfate+ so that manual-condition participants are not exposed to information about it that could prime them to choose it as the alternative offering.
- **Reusing the backend for other studies.** The intent is for one backend to serve multiple studies with different products and shelf images, and the `study` URL param exists for that. Today, swapping stimuli means editing those two files and redeploying; selecting content by `study` at runtime is not built yet.

## Why the document order is shuffled

If the focal product always sat in the same position (e.g. always first, or alphabetical), the `manual` condition would take a predictable, probably too-short amount of time regardless of document length — undermining the 1–2 minute target and making manual search trivially easy relative to asking the AI. To avoid that:

- The product list is shuffled (not just the focal product's position — the whole list) using a seeded random shuffle.
- The seed is derived deterministically from the participant's Prolific ID, so the same participant always sees the same order (reproducible for analysis) without needing to separately store "what order did we show them."
- This shuffle happens once, client-side, and the resulting document text is reused both for on-screen rendering *and* as the context sent to the AI backend — so the AI conditions and the manual condition are always working from the same shuffled document, generated in exactly one place.

## Data being collected

- **Conversation transcripts** (`chat_default` / `chat_price` only): Prolific ID, condition, and every chat turn (role, content, timestamp).
- **Identifiers on every record:** Prolific ID (`pid`), Qualtrics `ResponseID` (`sid`, the join key to survey data), Prolific session ID (`psid`) and study ID (`study`). Logging is not built yet; the app already parses these.
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

## Hosting and deployment

Hosted on Firebase Hosting, project `ai-research-task` (`https://ai-research-task.web.app`). Config is in `firebase.json` and `.firebaserc`.

```
flutter build web --release
firebase hosting:channel:deploy qualtrics-test --expires 7d   # temporary preview URL
firebase deploy --only hosting                                 # live site
```

- **Framing.** A `Content-Security-Policy: frame-ancestors` header allows embedding only from `https://lse.eu.qualtrics.com` (plus `localhost` for testing). No `X-Frame-Options` is set, since that would block the embed.
- **No stale builds.** Every file is served `Cache-Control: no-cache`, and `web/flutter_bootstrap.js` deliberately omits Flutter's service worker, which otherwise caches app files in the browser and can keep serving an old build (and old study content) after a redeploy. A browser that loaded an earlier build may need its site data cleared once.
- **Local run.** Use `flutter run -d chrome` and open e.g. `http://localhost:<port>/?stim=36bde6&pid=TEST`. A Linux desktop build has no URL, so it only shows the error screen.

## Testing

`flutter test` runs the suite on the Dart VM. Some bugs only appear on the web, so also run the config tests there: `flutter test --platform chrome test/config/session_config_test.dart`. (One such bug: `1 << 32` is `0` in JavaScript, which broke the fallback session ID.)

## Open items to confirm before building

- The exact wording of the price-salience system prompt — the version in the implementation plan is a starting point, not pretested language.
- Whether and how `study` should select stimulus content (products, shelf image) at runtime, for running multiple studies from one deployment.

A more detailed, implementation-level plan (file structure, schemas, library choices) exists alongside this README for when we're ready to start building.
