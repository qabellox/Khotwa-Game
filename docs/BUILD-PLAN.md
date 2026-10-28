# Khotwa - build plan

How to take the current prototype to a store-quality 2D Android release, and which model tier to
use for which part of the work. Companion to `docs/PROJECT.md` (what the game is) and
`.opencode/skills/khotwa-game/SKILL.md` (agent context).

Status: draft for review. Nothing here is binding until the paths in section 4 are chosen.

---

## 1. What the model actually does

A common misconception worth clearing first: the model does **not** scrape art off the web and
render it into 2D sprites. It writes code, data and text. Art comes from either the AssetForge
pipeline, a commissioned artist, or a mix. So the model's job is **decisions plus code**, and the
hard part is the decisions.

"Just follow my instructions" works for the 70% of the job that is mechanical. It fails on the
30% where the instruction is a goal, not a step - "make it feel good", "make the transition
smooth", "make it not stutter on a cheap phone". Those need thousands of micro-decisions that
nobody writes down, plus the ability to notice when the result is technically correct but feels
dead.

A weaker model typically:

- follows the literal instruction and stops at "it compiles and runs"
- loses architectural coherence over a long build and quietly contradicts earlier decisions
- accumulates small errors that compound (an asset pipeline choice at step 3 becomes a rebuild at
  step 300)
- debugs by guessing instead of forming and testing a hypothesis
- cannot self-assess quality, so it reports success on something mediocre

That is the entire difference. Not typing speed, not knowledge of the API.

## 2. Where a free model reaches Opus-quality output

Judgment estimate for *this* game, based on observed work in this repo (not a benchmark).

| Workstream | Share of job | Free model at comparable quality | What breaks first |
| --- | --- | --- | --- |
| Content and data: questions, strings, i18n, balance tables | 15% | 90-95% | Nothing much; volume work |
| UI screens: menus, settings, HUD, shop layout | 20% | 85-90% | Visual taste, spacing rhythm |
| Core systems: state machine, spawners, save/load, progression, economy | 20% | 75-85% | Coherence across files |
| Polish: animation, easing, transitions, particles, shaders | 20% | 50-65% | Game feel, timing curves |
| Device and perf debugging, Android export, signing | 10% | 50-65% | Sparse engine knowledge |
| Billing, consent, compliance, store listing | 10% | 60-75% | Money-path correctness |
| Whole-build architecture coherence | 5% | 40-60% | Error accumulation |

Weighted: roughly **70-75% of the work at comparable quality, for about 2% of the token price**.

Read that honestly in both directions. It is not "free models can't do it" - three quarters of the
job is genuinely fine. It is also not "free models are equal" - the missing quarter is
concentrated exactly where players form their opinion, and it costs 3-5x more iterations to
approach it.

Evidence from this repo, not theory: a free reasoning model given an explicit "list the
correct-answer indices" task read the right file and returned a prose summary instead, without the
indices. A frontier model does that correctly. Small gap per call, large gap over 3,000 calls.

## 3. Why one model costs more than another

Price tracks **compute per token**, not effort or fairness. Bigger models need more GPU-seconds
per token, cost more to train, and command more demand. Within one family, price also reflects
how much thinking happens before the answer.

| Tier | Example | Input /1M | Output /1M | Cache read /1M |
| --- | --- | --- | --- | --- |
| Frontier standard | `openai/gpt-5.5` | $5 | $30 | $0.50 |
| Frontier fast | `openai/gpt-5.5-fast` | $12.50 | $75 | $1.25 |
| Frontier pro | `openai/gpt-5.5-pro` | $30 | $180 | none |
| Free hosted | `opencode/deepseek-v4.1-flash-free` | $0 | $0 | $0 |

Two structural facts that matter more than the headline:

1. **Cache reads dominate long sessions.** This project's 102.6M cache reads cost $51 on
   standard, $128 on fast, and $3,077 on pro (no cache discount). Cache pricing decides the bill.
2. **Output tokens are the expensive half.** A polish loop that regenerates a screen five times
   pays five times the output cost. Better first-try accuracy is worth more than a cheaper input
   price.

## 4. Three build paths

### Path A - free only

All work on free models, current six-agent team.

- Feasible through milestone M5 (a complete, coherent, playable game).
- Art consistency handled by the AssetForge pipeline plus human curation of the shortlist.
- Model bill: **$0**. Real cost: calendar time, because free tiers throttle, get retired mid
  project, and need 3-5x more correction rounds.
- Weakest points: polish passes and obscure engine bugs. Expect to settle for "good", not
  "distinctive".
- Verdict: workable, and the honest way to start. Not the way to finish.

### Path B - hybrid (recommended)

Free models carry volume; a frontier model is rented by the hour for the four places where quality
compounds.

| Work | Model | Why |
| --- | --- | --- |
| Content, UI screens, wiring, tests, docs, CI | free | Volume, low ambiguity |
| Architecture and milestone design | frontier, short sessions | Mistakes here cost weeks |
| Polish passes (feel, timing, transitions, effects) | frontier, short sessions | Taste and iteration |
| Money path: billing, consent, compliance | frontier | Bugs cost real money and store rejection |
| Hard perf/device debugging | frontier | Hypothesis-driven, sparse knowledge |

Roughly **80% of hours on free, 20% on frontier**. At measured burn rates that is **$300-$900** of
frontier tokens, not $1k-$2k.

### Path C - frontier throughout

Fastest and highest quality, and the only path with a predictable number of iterations. Measured
extrapolation: **$1k-$2k models, $2k-$5k total cash, 300-400 hours**.

## 5. Milestones and gates

Each gate is a stop/go decision. Do not start the next milestone on a fail.

| # | Milestone | Deliverable | Done when | Model tier |
| --- | --- | --- | --- | --- |
| M0 | Specs | Written specs for the 9 systems in section 6 | Every spec has inputs, outputs, states, failure modes | frontier (short) |
| M1 | Vertical slice | 1 biome, 1 character, 5 screens, 1 transition set, Android dev build | Runs 60 fps on a low-end phone for 5 minutes without a hitch | mixed |
| M2 | Core loop | Full runner, spawner, scoring, health, revive quiz | 10-minute session with no logic bug | free |
| M3 | Meta | Progression, currency, unlockables, save/load, settings, onboarding | Fresh install to full loop, survives app kill | free |
| M4 | Content | 3-8 biomes, 150-400 assets, 40+ questions, AR+EN with RTL | Art passes a consistency review; no English leaking into AR | mixed |
| M5 | Polish | Animation, transitions, particles, audio mix, haptics, screen shake | A stranger plays 5 minutes and does not say "prototype" | frontier |
| M6 | Platform | Signed AAB, ARM64, target API, back button, safe areas, lifecycle | Installs from a closed-testing track on 3 real devices | frontier |
| M7 | Compliance | Data safety, content rating, consent, privacy policy, store listing | Submitted and accepted by Play review | frontier |
| M8 | Launch | Closed test with 12+ testers, 14 days, crash-free | Production access granted | - |

Gate on M1 is the important one: it measures real tokens-per-hour and real visual quality before
committing to M2-M5.

## 6. Systems that need a written spec first

Writing these before building is the single highest-leverage activity, because a wrong assumption
here is a rewrite later. Each is one page.

1. Game loop and difficulty curve (speed, spawn density, fairness rules)
2. Progression and economy (what is earned, what is bought, what is never sold)
3. Save format and migration (schema versioning from day one)
4. Revive and question flow (bank size, repetition rules, timeout, accessibility)
5. Localisation and RTL (Arabic-first, English second, string keys, font fallback)
6. Art pipeline (naming, scale, palette, atlas budget, animation frame counts)
7. Audio (music states, ducking, mute persistence, mobile unlock)
8. Monetisation - if any (rewarded ads only, or IAP, or neither) and consent
9. Analytics and crash reporting (events worth collecting, privacy constraints)

## 7. Scope correction

Your list included "authentication, logging and pricing and purchasing". For a Play Store game:

- **No login is needed.** A single-player runner needs no account. Adding one adds a backend, a
  privacy surface and a support burden for zero gameplay value.
- **No custom pricing or purchasing stack.** Google Play Billing handles price, tax, currency and
  receipts. The work is a thin client plus server-side or local receipt validation.
- **Analytics is not "logging".** It is a small, deliberate event set.

If you actually want a web store, accounts and a purchase funnel, that is a second product with
its own backend, and it is the largest scope risk in the list. Decide explicitly, not by drift.

## 8. What free models are genuinely bad at here

Named so they can be routed around rather than discovered late:

- Godot 4 Android export failures (Gradle, JDK, keystore, ABI splits) - sparse in training data,
  needs iterative hypothesis testing.
- Shader and CanvasItem performance work on low-end GPUs.
- Godot Play Billing plugin integration - known to be fiddly; docs lag the engine.
- Anything where "it runs" is not "it is right": feel, timing, readability, contrast.
- Long sessions: forgetting a decision made 200 steps earlier and contradicting it.

## 9. Definition of done for "store quality"

Not vibes. All of these, per milestone:

- 60 fps on a low-end Android device from the last 4 years, no frame spikes over 33 ms in a
  5-minute session.
- Cold start under 3 seconds to interactive.
- Zero crashes in a 30-minute session; crash reporting wired and verified.
- Every screen reachable, every back press handled, no dead ends.
- Arabic renders correctly right-to-left with no clipped glyphs.
- Touch targets at least 48 dp; nothing depends on hover.
- Save survives app kill, device rotation and an update.
- Art passes a consistency check: same palette, same lighting direction, same line weight.
- A stranger plays 5 minutes unaided and can explain the goal and the quiz rule.

## 10. Risk register

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Free model retired mid-build | Team stalls | Fallback chain already defined; keep two viable models per role |
| Art inconsistency across 300 assets | Looks cheap, kills the "store quality" claim | Palette and style sheet first; batch review every 20 assets |
| Long-horizon incoherence | Regressions, rewrites | Written specs, one milestone at a time, tests at each gate |
| Play Billing integration | Weeks lost, money-path bugs | Frontier model, official plugin only, test with licence testers |
| Perf on low-end devices | Bad reviews | Low-end device in hand from M1, not M6 |
| Scope creep from web-store ideas | Doubles the project | Decide section 7 explicitly before M0 |
| Content thinness (10 questions) | Low retention | 40+ questions by M4, written as data not code |

## 11. Recommendation

Run **Path B**. Start with M0 and M1 only. M0 is a few frontier sessions ($20-$40); M1 is
40-60 hours and $300-$600 of mixed tokens. That buys a measured burn rate, a real Android build on
a real phone, and a visual answer to "does this look like a store game".

Everything after M1 is priced against that measurement instead of against my guess.
