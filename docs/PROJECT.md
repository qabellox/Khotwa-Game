# Khotwa - project brief

This is the durable, git-tracked summary of what Khotwa is and how the project runs. The
machine-readable context for agents lives in `.opencode/skills/khotwa-game/SKILL.md`; this file
is the human-readable equivalent.

## What it is

Khotwa (خطوة, "a step") is a 2D endless runner made with **Godot 4.7.2** and exported to the
web. It is an **anti-drug and addiction-awareness game** for Arabic-speaking players: you run
through three lanes, dodge drugs and junk food, collect coins, fruit and healthy items, and when
your health reaches zero the only way back into the run is to answer an Arabic awareness
question correctly within 15 seconds.

- Play: https://khotwa-preview.vercel.app/ (single hosted copy, landscape only)
- Source: https://github.com/qabellox/Khotwa-Game (public)

## How it plays

| Element | Behavior |
| --- | --- |
| Lanes | 3 horizontal lanes; the player stays at x = 960 and the world moves. |
| Controls | Up/W or Left/A, Down/S or Right/D; tap the lane on touch. One short tap starts the game. |
| Score | +1 per second; coins +5, fruit +10 and +25 health, healthy item +15 and +40 health. |
| Health | 100; obstacles (drugs, junk food) deal 25 with 0.6 s invulnerability. |
| Difficulty | 430 -> 1600 px/s, +15 every 1.6 s with a 70 px/s² ramp. |
| Comfort caps | Background scroll and speed lines capped at 640 px/s; lane slide is damped (11/s, 560 px/s max). |
| Death | `GAME OVER` -> `REVIVE` (15 s Arabic quiz, correct = full health + 100 score) or `RESTART`. |
| Orientation | Portrait is blocked by a rotate gate; the engine boots only in landscape. |

The quiz bank is 10 Arabic questions about addiction, drugs, exam stress, exercise, mental
health and helplines (`khotwa/question_manager.gd`).

## Architecture

- One scene: `khotwa/main.tscn` (`Track`, `Player/Sprite`, `GameManager`, `QuestionManager`,
  `ItemSpawner`, `SpeedLines`, `UI`).
- No Camera2D: the viewport is fixed and every entity moves.
- No CollisionShape2D: collision is manual `Rect2` intersection against `hit_size` metadata.
- ~1,100 lines of gameplay GDScript plus ~350 lines of QA/capture helpers.
- Renderer **Compatibility / WebGL 2**, **threads off**, design space **1920x1080**, stretch
  `canvas_items` / `keep`. This is what makes it work on mobile Safari and Android without
  cross-origin isolation.
- Web shell (`khotwa/web_support.gd` plus the export template) handles boot recovery, the
  rotate gate, canvas sizing and on-device diagnostics.

## Build and deploy

```powershell
# local build -> dist/web
godot --headless --path khotwa --export-release "Web" ..\dist\web\index.html
```

**Push to `main` is the deploy.** The `Web build` GitHub Action exports the game in about 30
seconds and force-pushes the artifact to the generated `web-build` branch; Vercel tracks
`web-build` as production and publishes https://khotwa-preview.vercel.app/. `vercel.json`
disables Vercel Git deploys for `main`.

- Never hand-edit `dist/web` or the `web-build` branch; they are generated.
- Manual fallback: `vercel deploy --prod` from `dist/web`.
- The Vercel production-branch setting has no writable REST route; it lives in the dashboard
  (`Settings -> Environments -> Production -> Branch Tracking`) and resets to `main` if the
  repository is re-linked.

## Costs

Two different products. The numbers below are for the **store-quality Android release**, not the
current prototype (which cost $0 in models and 20-60 hours to build).

| Scenario | Hours | Model spend | Other cash (art/audio, devices, QA, store) | Total cash |
| --- | --- | --- | --- | --- |
| Lean: mixed model tiers, heavy caching, AI art + cleanup, self-QA | 200-250 | $700-$1,800 | $1,500-$3,500 | **$2.5k-$5.5k** |
| Standard: frontier model for design/code, some commissioned art | 300-400 | $2,000-$4,500 | $3,500-$7,000 | **$6k-$12k** |
| Premium: frontier-pro, heavy regeneration, commissioned art/audio, multi-device QA | 450-700 | $8,000-$20,000 | $10,000-$25,000 | **$20k-$45k** |

Model math: agentic coding burns roughly 0.6M-2M tokens per productive hour. 300 hours at 1M
tokens/hour is ~300M tokens. At frontier-standard pricing ($5/M input, $30/M output) with 60%
cache hits, that is about $2k; at frontier-pro pricing ($30/M input, $180/M output) without
cache discounts it is $15k+ for the same work.

Add-on cash items: Google Play Console $25 one-time; low-end test device $150-$400; optional
iOS $99/year; privacy policy and store assets mostly time. New personal Play accounts also need
12 testers for 14 continuous days before production access.

A stronger model compresses the coding loop, not art direction, game-feel tuning, device QA or
store compliance. Those remain the schedule risk.

Running the web version: Vercel Hobby $0 (100 GB/month, ~4,000 first loads, non-commercial);
Pro $20/month for 1 TB and commercial use. A Play release has no hosting bill.

## Agent team

Defined in `.opencode/agents/`, routed by `feedback` -> `orchestrator` -> `thinker` /
`asset-pipeline` / `builder` / `tester`. Roles and permissions are model-independent; only the
`model:` line picks a brain, and the orchestrator substitutes the nearest available model if one
is retired. Project agents, skills and the `memory` / `assetforge` / `playwright` MCP servers are
discovered from the **session location**, so open the session at the project root.

## Verification

- Serve `dist/web` over local HTTP (`python -m http.server 8900`), never `file://`.
- `C:\Users\Qebaa\Projects\_tools\mobile_suite.py` runs four mobile viewports and checks boot,
  rotate gate, tap start, score, pause and resume.
- Live verification compares `index.pck` byte-for-byte with `origin/web-build` using
  `cmd /c "git show origin/web-build:index.pck > file"` (PowerShell redirection corrupts
  binaries).
