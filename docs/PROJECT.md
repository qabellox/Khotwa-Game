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

Measured baseline from the local OpenCode database: the Khotwa sessions on 27-28 Oct 2026 used
3.43M input, 0.42M output, 0.64M reasoning and 102.6M cache-read tokens. At frontier-standard
prices that is **~$100**; at fast-tier **~$250**; at Opus-class prices **~$285**. That covered
the prototype audit, the comfort fix, the web shell, CI, deployment and mobile testing.

A store-quality build is 4-8x that agent work (6k-15k lines, 3-8 biomes, 15-25 screens, Android
target), while art polish and device QA stay human-heavy.

| Scenario | Model spend | Other cash | Total (no salary) | Time |
| --- | --- | --- | --- | --- |
| Lean: standard tier, AI art + cleanup, self-QA | $400-$1,000 | $300-$700 | **$0.7k-$1.7k** | 250-300 h |
| Standard: mixed tiers, some commissioned art/audio | $900-$2,000 | $1,000-$3,000 | **$2k-$5k** | 300-400 h |
| Premium: heavy regeneration, commissioned art/audio, multi-device QA | $2,000-$4,000 | $4,000-$10,000 | **$6k-$14k** | 400-600 h |

Planning number for the standard path: **$3k-$5k cash and ~350 hours**, of which **$1k-$2k is
models**. Cache pricing dominates: the same 102.6M cache reads cost $51 on a standard tier and
$3,077 on a pro tier without cache discounts, so use pro models only for isolated hard problems.

Play costs: $25 one-time console, $150-$400 low-end test device, 12 testers for 14 continuous
days on new personal accounts, optional iOS $99/year. A stronger model compresses code work, not
art direction, game-feel tuning, device QA or store compliance.

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
