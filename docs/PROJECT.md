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

Estimates in USD, October 2026, for this exact scope.

| Route | Cost |
| --- | --- |
| Godot endless-runner template | $10-$80 (before reskin, quiz, Arabic, web shell) |
| Freelancer, low-cost market | $1,500-$4,000 |
| Freelancer, US/EU | $6,000-$20,000 |
| Small agency | $20,000-$60,000 |
| Rebuilding by vibe coding on free models | $0 in models, 20-60 hours of human time |
| Rebuilding with paid chat subscriptions | $20-$40/month for 2-6 weeks |
| Rebuilding with pay-as-you-go API | $30-$250 total |

Running costs: Vercel Hobby $0 (100 GB transfer/month, ~4,000 first loads, non-commercial
only); Vercel Pro $20/month (1 TB, commercial); GitHub $0 (public repo); Godot $0; optional
domain $10-$20/year. A first visit downloads about 25 MB, so bandwidth is the first limit a
large launch would hit.

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
