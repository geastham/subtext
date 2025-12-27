Below is a **product spec + technical spec** you can hand to design/engineering to build a “dating copilot” iOS app that (1) makes the “paste convo → get advice” workflow feel native and (2) meaningfully improves privacy by keeping as much as possible **on-device**.

---

## 1) Product specification (PRD)

### 1.1 Product concept

**A private, on-device “conversation coach”** for Gen Z: users import or paste a chat thread (iMessage/WhatsApp/IG DMs text), choose a goal (“reply well”, “set a boundary”, “figure out if this is a red flag”), and get **actionable suggestions**: reply drafts, tone options, safety checks, and coaching prompts.

### 1.2 Target user + jobs-to-be-done

**Primary:** Gen Z (18–27) who already use ChatGPT by pasting conversations.
**JTBD:**

* “Help me reply without sounding desperate/mean.”
* “Tell me what’s going on here (mixed signals?).”
* “Help me set a boundary / say no.”
* “Help me de-escalate / avoid spiraling.”
* “Spot manipulation/red flags.”
* “Give me 2–3 reply options in my voice.”

### 1.3 Core user flows

1. **Import / Paste**

* Paste text, share-sheet import, or manual entry.
* “Who’s who?” quick role labeling (Me / Them).
* Optional: mark sensitive parts for redaction.

2. **Choose intent**

* Quick intents: *Reply*, *Interpret*, *Boundary*, *Flirt*, *Conflict repair*, *Closure*.
* Optional sliders: directness, warmth, flirtiness, length.

3. **Coaching output**

* 3 reply drafts + “why this works” bullet points.
* “Risk flags” section (if relevant): coercion, love bombing, guilt-tripping, etc.
* “Ask-back questions” to clarify missing context.

4. **Refine**

* Tap-to-edit drafts; regenerate with constraints.
* “Match my style” (learn preferences locally).

5. **Privacy controls**

* “On-device only” mode (default).
* Optional “bigger brain mode” if you later add a cloud fallback (see tech).

### 1.4 Functional requirements (MVP)

* Conversation ingest (paste/share sheet), speaker labeling, trimming.
* On-device analysis: summary, sentiment/tone, intent classification, rewrite generation.
* Reply generation with structured output (so UI can render consistently).
* Local history (encrypted), search, delete-all, per-thread delete.
* Safety layer: refuse harmful/abusive coaching; provide supportive guidance.

### 1.5 Non-goals (MVP)

* Full messaging client.
* Real-time keyboard extension (could be V2).
* Full “relationship therapist” claims (avoid medical framing).

### 1.6 Safety & trust requirements

* **No judgmental language** (“you’re toxic”); keep it supportive and neutral.
* Detect cues of **abuse/coercion** and pivot to safety-first suggestions.
* Clear disclaimers: “Not professional advice.”

### 1.7 Metrics

* Activation: % who complete first import → generate replies.
* Retention: weekly active, “threads coached per week.”
* Quality: thumbs up/down per suggestion, edit distance on chosen draft.
* Privacy trust: % staying on “on-device only”, and settings visits.

---

## 2) Technical specification (TRD)

### 2.1 Platform + constraints

You have two viable “privacy-first” paths:

**Path A (best Apple-native): Use Apple’s on-device Foundation Models framework**
Apple now provides a **Foundation Models** framework that “gives access to Apple’s on-device large language model that powers Apple Intelligence,” supporting language tasks and structured output/tool calling. ([Apple Developer][1])
⚠️ Availability is OS-version gated (the docs show very new minimum OS versions), so you likely need a fallback for older devices.

**Path B (portable): Ship your own on-device model via Core ML (or similar)**
Core ML runs models fully on-device and explicitly highlights privacy/offline benefits and support for transformer operations/compression. ([Apple Developer][2])
Apple ML Research also shows how larger open LLMs can run locally using Core ML optimizations (example with Llama). ([Apple Machine Learning Research][3])

**Recommendation:** architect for **A + B**:

* Default to **Foundation Models** on supported OS/devices for best UX + Apple privacy posture.
* Fall back to **Core ML–packaged** smaller model(s) for older OSes / non-Apple-Intelligence devices.

### 2.2 High-level architecture

**Client-only (MVP):**

* UI (SwiftUI)
* Conversation store (Core Data / SQLite)
* On-device LLM layer:

  * `FoundationModels` client (if available)
  * else `CoreMLLLM` client (your shipped model)
* Safety + policy layer (local rules + classifier)
* Telemetry (privacy-preserving, opt-in)

**Optional later: privacy-preserving cloud escalation**

* For “hard” requests, use Apple’s Private Cloud Compute style approach *if you ever integrate it*, or your own encrypted cloud. Apple’s PCC is designed so data sent for larger-model processing is not accessible to anyone other than the user (by Apple’s design claims). ([Apple Security Research][4])
  (If you do your own cloud, you’ll need a comparably strong story—otherwise keep it device-only.)

### 2.3 Data model (local)

* `ConversationThread`

  * `id`, `title`, `createdAt`, `updatedAt`
  * `participants`: {meLabel, themLabel}
  * `messages`: `[Message]`
  * `userNotes` (optional)
* `Message`

  * `timestamp?`, `speaker` (me/them/unknown), `text`
* `CoachingSession`

  * `threadId`, `intent`, `constraints` (tone sliders), `outputs` (structured)

**Storage security**

* Encrypt at rest using iOS Data Protection + Keychain-managed keys.
* “Delete all data” must securely wipe DB + derived caches (embeddings, temp files).

### 2.4 Model interaction design (structured, UI-friendly)

Use **structured outputs** so the UI isn’t parsing prose:

```json
{
  "summary": "...",
  "situationSignals": ["mixed_signals", "warm_then_cold"],
  "riskFlags": [{"type":"coercion","evidence":["..."],"severity":"high"}],
  "replyOptions": [
    {"label":"Warm + clear","text":"...","rationale":["..."]},
    {"label":"Playful","text":"...","rationale":["..."]},
    {"label":"Boundary","text":"...","rationale":["..."]}
  ],
  "followUpQuestions": ["..."]
}
```

Apple’s Foundation Models framework specifically calls out language understanding and structured output / tool calling as first-class capabilities. ([Apple Developer][1])

### 2.5 “On-device only” privacy posture

**Default behavior**

* No conversation text leaves device.
* No server logs of user content.
* Optional analytics: only aggregate counters (e.g., “generated 3 drafts”), never raw text.

**User-facing controls**

* “On-device only” toggle (default ON, ideally not even a toggle in MVP).
* Per-thread lock (FaceID) optional.
* Redaction mode before analysis (mask names/phones).

### 2.6 Safety layer (local)

Two layers:

1. **Hard rules** (fast): self-harm, threats, sexual content involving minors, stalking instructions, etc.
2. **Classifier** (on-device): abuse/coercion detection → switch to safer output templates.

Output policy examples:

* If coercion/abuse likely: prioritize *boundary + safety + resources*, avoid “how to persuade them.”

### 2.7 Performance targets

* First token under ~1–2s on modern devices for typical thread sizes (e.g., last 20–40 messages).
* Energy guardrails: throttle generation length; prefer short drafts + “expand” button.
* Streaming tokens (if API supports) for perceived speed.

### 2.8 Model strategy options

**Option A: Foundation Models framework**

* Pros: best privacy marketing alignment, no model download, native tool calling/structured outputs. ([Apple Developer][1])
* Cons: OS/device availability constraints; less control over model weights.

**Option B: Core ML shipped model**

* Pros: broader OS coverage, full control, fully offline, predictable behavior. Core ML emphasizes on-device privacy/offline execution and transformer support/compression. ([Apple Developer][2])
* Cons: app size (model weights), performance variability across devices, quantization work.

**R&D note:** Apple’s MLX ecosystem is also relevant for Apple-silicon ML workflows (esp. prototyping/finetuning on Mac), but for iOS app runtime you’ll typically still want Core ML / Apple frameworks for deployment. ([GitHub][5])

### 2.9 App Store + compliance (practical checklist)

* Clear consent for importing sensitive messages.
* Privacy Nutrition Label accurately reflects: “Data not linked to you / not collected” if true.
* Avoid claims like “therapy” or “medical advice.”

---

## 3) Suggested MVP scope (6–10 weeks build, depending on team)

**MVP features**

* Paste/share import, speaker labeling
* 5 intents
* 3 drafts + rationale + follow-up questions
* Local encrypted storage + delete controls
* On-device inference (Foundation Models where available; else Core ML small model)
* Basic safety detection + safe output templates

**V2**

* Style personalization (local)
* “Keyboard extension” for inline coaching
* Optional cloud escalation (only if you can keep a credible privacy story)

---

## 4) Key decisions you should lock early

1. **Minimum iOS version** you’re willing to support (this determines how viable “Foundation Models first” is). ([Apple Developer][1])
2. **Model footprint** (if shipping Core ML): small (1–3B quantized) vs medium.
3. **Default retention**: store threads indefinitely vs auto-expire (privacy vs convenience).
4. **Abuse/safety stance**: define what you will *not* generate (and how you respond).

---

If you tell me your planned **minimum iOS version** and whether you want **zero cloud** in v1, I can turn this into a tighter spec with: concrete API surfaces (Swift protocols), module breakdown, screen-by-screen UX requirements, and a test/eval plan for reply quality + safety.

[1]: https://developer.apple.com/documentation/foundationmodels?utm_source=chatgpt.com "Foundation Models | Apple Developer Documentation"
[2]: https://developer.apple.com/machine-learning/core-ml/?utm_source=chatgpt.com "Core ML Overview - Machine Learning - Apple Developer"
[3]: https://machinelearning.apple.com/research/core-ml-on-device-llama?utm_source=chatgpt.com "On Device Llama 3.1 with Core ML - Apple Machine Learning Research"
[4]: https://security.apple.com/blog/private-cloud-compute/?utm_source=chatgpt.com "Private Cloud Compute: A new frontier for AI privacy in the cloud"
[5]: https://github.com/ml-explore/mlx?utm_source=chatgpt.com "GitHub - ml-explore/mlx: MLX: An array framework for Apple silicon"
