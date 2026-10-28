---
name: Khotwa Game
description: Complete context for the Khotwa project - what the game is, its purpose, gameplay loop, systems, quiz content, assets, tech constraints, build/deploy pipeline, running costs, agent team, and known risks. Load this before answering any question about what Khotwa is, how it works, what it costs to build or buy, or how the project is operated.
---

# Khotwa - project context

## 1. Identity

- **Name:** Khotwa (خطوة, "a step"). README tagline: *Break Free*.
- **What it is:** a 2D endless runner made in **Godot 4.7.2**, exported to the web, playable in any phone/tablet/desktop browser in landscape.
- **Language:** the game UI is English (`START`, `SCORE`, `PAUSED`, `REVIVE`, `RESTART`, `TIME`, `GAME OVER`); the revival quiz content is **Arabic** and right-to-left, rendered with Tahoma/Arial.
- **Purpose:** an **anti-drug / addiction-awareness game**. The runner dodges drugs and junk food, collects coins, fruit and healthy items, and the only way to revive after "dying" is to answer a health/awareness question correctly. It is an edutainment piece, not a commercial arcade game.
- **Audience:** Arabic-speaking teenagers/young adults, mostly on phones.
- **Hosting:** a single public URL - https://khotwa-preview.vercel.app/ - served by Vercel project `khotwa-preview` (team `port-nova`).
- **Repo:** https://github.com/qabellox/Khotwa-Game (public).

## 2. Player experience

1. Page loads a black boot screen, then the menu with a green `START` button (also starts with Tab/Enter or any tap).
2. The runner stands at a fixed screen position and the **world moves toward the player**.
3. Player switches between **3 horizontal lanes**; obstacles and pickups fall down the lanes.
4. Score rises +1 per second. Survive, collect, and keep health above zero.
5. At zero health the run ends (`GAME OVER`) with two choices:
   - `REVIVE` - opens an Arabic multiple-choice question with a **15-second** timer. Correct answer: full health, +100 score, run continues. Wrong answer or timeout: run is over.
   - `RESTART` - a fresh run.
6. `II` pauses; `RESUME` continues.

**Controls**

- Keyboard: Up/W or Left/A = lane up; Down/S or Right/D = lane down.
- Touch/mouse: tap the lane you want (tap left/right of the screen on mobile works because the nearest lane is chosen); a single short tap must start the game - never require a double tap.
- Portrait orientation is blocked by the web shell with a rotate gate; the engine does not boot until the device is landscape.

## 3. Game rules and numbers

| Rule | Value | Source |
| --- | --- | --- |
| Lanes | 3, fixed x = 960, y = 290 / 538 / 816 | `game_manager.gd` |
| Start speed | 430 px/s | `base_speed` |
| Max speed | 1600 px/s | `max_speed` |
| Speed increase | +15 px/s every 1.6 s, ramped at 70 px/s² | `speed_increment`, `speed_tick_interval`, `speed_ramp_rate` |
| Score | +1 per second | `score_per_second` |
| Health | 100; obstacle hit = -25; 0.6 s invulnerability after a hit | `max_health`, `hazard_damage` |
| Coin | +5 score, +1 coin, no heal | `item_spawner.gd` |
| Fruit | +10 score, +25 health | `item_spawner.gd` |
| Healthy item | +15 score, +40 health | `item_spawner.gd` |
| Fall speed of objects | exactly `game_speed` | spawners |
| Background scroll | capped at 640 px/s | `track.gd` `scroll_speed_cap` |
| Speed-line visuals | capped at 640 px/s | `speed_lines.gd` `visual_speed_cap` |
| Lane slide | damped follow, rate 11.0/s, max 560 px/s | `player.gd` |
| Question timer | 15 s | `ui.gd` `QUESTION_TIME` |

Damage is applied only when the player's manual hitbox (120x108, offset 45 px above the node) overlaps an obstacle's `hit_size` rect. There are **no CollisionShape2D nodes**; collision is hand-written `Rect2` math.

## 4. Quiz content (the educational core)

`khotwa/question_manager.gd` holds a 10-question Arabic bank. Themes:

1. Helping a friend showing signs of addiction.
2. Warning signs of drug use in a teenager.
3. Effect of repeated use on the brain.
4. Handling exam stress without drugs.
5. What is true about addiction (it is treatable).
6. Why an addicted person keeps using despite harm.
7. Best reaction the first time drugs are offered.
8. Effect of exercise on mental health.
9. Long-term effects of hallucinogens.
10. What to do when a craving is strong (call a helpline / trusted person).

Correct-answer indices in bank order: `1, 2, 0, 0, 1, 2, 3, 2, 0, 3`.

The bank is small (10 items). Games repeat quickly, and an empty bank would return a `"?"` placeholder, so any content expansion should add questions rather than replace them.

## 5. Code map

All game code is flat in `khotwa/` (no subfolders). About 1,795 lines of GDScript total; ~1,100 of them are the gameplay core.

| File | Lines | Role |
| --- | --- | --- |
| `game_manager.gd` | 204 | State machine (MENU/RUNNING/PAUSED/REVIVAL_HOTLINE/GAME_OVER), score, health, speed, coins, audio, signals, revive logic. |
| `ui.gd` | 310 | Builds the whole HUD in code: score panel, coin counter, health bar, pause overlay, game-over overlay, Arabic question popup, screen flash. |
| `player.gd` | 168 | Sprite-sheet animation (4 frames), damped lane slide, tap/keyboard input, manual collision checks, pain and death sprites. |
| `item_spawner.gd` | 131 | Spawns items that fly **horizontally** from the right; hazards (drug, unhealthy) and pickups (coin, fruit, healthy) with glow. |
| `question_manager.gd` | 121 | The Arabic question bank and random selection (never repeats the same question twice in a row). |
| `obstacle_spawner.gd` | 61 | Spawns drugs/junk that fall down a random lane. |
| `pickup_spawner.gd` | 60 | Spawns collectibles that fall down a random lane. |
| `track.gd` | 37 | Tiling railway background scrolled by a canvas-item shader. |
| `speed_lines.gd` | 30 | 20 procedural speed lines drawn with `draw_line`. |
| `web_support.gd` | 367 | Autoload: web build recovery, rotate gate messaging, diagnostics, canvas sizing. |
| `capture*.gd`, `test_*.gd`, `lane_guides.gd` | ~350 | Developer/QA helpers, not part of the shipped loop. |

Only one scene: `khotwa/main.tscn` with `Main` -> `Track`, `Player/Sprite`, `GameManager`, `QuestionManager`, `ItemSpawner`, `SpeedLines`, `UI`. There is **no Camera2D anywhere** - the viewport is fixed and the world moves.

## 6. Assets

`khotwa/assets/` holds the original hand-supplied art and audio (~18.8 MB, one generated asset):

- **Player:** `sprite3.png` (4-frame runner sheet, 352x768 per frame), `pain.png`, `dead.png`.
- **Hazards:** `drug.png`, `unhealthy.png` (same image content, different labels in game).
- **Pickups:** `coin.png`, `fruit.png`, `healthy.png`.
- **Backgrounds:** `railway.png` (live track), plus `rail.png`, `rail_loop.png`, `track.png`, `track_loop.png`, `track_new.jpeg`, `shop.png`.
- **Fonts:** Arial, Arial Bold, Tahoma (Arabic).
- **Audio:** `bgm.mp3`, `coin_collect.mp3`, `pain.mp3`, `heal.mp3`, `death.mp3`.
- **Generated:** `assets/generated/sprites/smoke-coin.jpg` (AssetForge output, 7 KB) - currently **untracked in git**, which is why CI builds differ from the old local export by that one asset.

Asset conventions live in the `asset-naming` skill; art direction lives in `game-visual-rules`.

## 7. Tech constraints (do not break)

- Godot **4.7.2**, renderer **Compatibility / WebGL 2**, **threads off** (no SharedArrayBuffer, no COOP/COEP headers).
- Design space **1920x1080**, stretch `canvas_items`, aspect `keep`; landscape only.
- Web export only through the Godot pipeline; never hand-edit `dist/web/index.html` or `index.js`.
- `dist/` and `khotwa/build/` are gitignored. `dist/web` is only a local verification copy.
- Mobile is the primary target: one-tap start, no hover-only affordances, tap targets >= 72 px in design space, DPR capped, no per-frame allocation in `_process`.

## 8. Build and deploy

```powershell
# local build (writes dist/web)
godot --headless --path khotwa --export-release "Web" ..\dist\web\index.html
```

**Push to `main` is the deploy.** `.github/workflows/web-build.yml` exports the game in ~30 s using the committed template `tools/godot-templates/web_nothreads_release.zip`, then force-pushes the artifact to the generated `web-build` branch. Vercel tracks `web-build` as its production branch (`branchMatcher = equals:web-build`) and publishes it to https://khotwa-preview.vercel.app/. `vercel.json` disables Vercel Git deploys for `main` so source pushes create no preview builds.

- `web-build` is **generated output**: never edit it by hand, never commit to it.
- Manual fallback: `vercel deploy --prod` from `dist/web`.
- Production branch tracking has **no writable REST API route**; it is set in the Vercel dashboard at `settings/environments` -> Production -> Branch Tracking. Re-linking the repo resets it to `main`.
- A Vercel API token cannot be minted for this app (`403 Cannot create tokens for this app`), which is why the pipeline depends on the GitHub integration.

## 9. What it costs

### Measured baseline (this project, 27-28 Oct 2026)

From the local OpenCode database, the Khotwa sessions (prototype audit, camera/scroll fix, web
shell, CI pipeline, Vercel promotion, mobile testing, docs) consumed:

| Metric | Tokens |
| --- | --- |
| Input | 3.43M |
| Output | 0.42M |
| Reasoning | 0.64M |
| Cache read | 102.6M |

Converted to frontier prices, that entire body of work costs:

| Tier | Input | Output | Cache read | Total |
| --- | --- | --- | --- | --- |
| `gpt-5.5` ($5/$30/$0.50) | $17 | $32 | $51 | **~$100** |
| `gpt-5.5-fast` ($12.50/$75/$1.25) | $43 | $79 | $128 | **~$250** |
| Opus-class estimate ($15/$75/$1.50) | $51 | $79 | $154 | **~$285** |

**Two intense days of frontier-assisted work cost $100-$285 in tokens.** That is the calibration
point. It is also why the first "prototype" estimate was not crazy, and why agency-style
production numbers look inflated for solo vibe coding.

### Store build = baseline x scope multiplier

A store build has 4-8x the agent work (6k-15k lines, 3-8 biomes, 15-25 screens, Android target),
but art polish and device QA are human-heavy, not token-heavy.

| Scenario | Scope x | Model spend | Other cash | Total (no salary) | Time |
| --- | --- | --- | --- | --- | --- |
| Lean: standard tier, AI art + cleanup, self-QA | 4x | $400-$1,000 | $300-$700 | **$0.7k-$1.7k** | 250-300 h |
| Standard: mixed tiers, some commissioned art/audio | 6x | $900-$2,000 | $1,000-$3,000 | **$2k-$5k** | 300-400 h |
| Premium: heavy regeneration, commissioned art/audio, multi-device QA | 10x | $2,000-$4,000 | $4,000-$10,000 | **$6k-$14k** | 400-600 h |

Planning number for the standard path: **$3k-$5k cash and ~350 hours**. Cash here excludes
your own labour; with AI-generated art the "other cash" can stay near the low end.

### The pro-tier trap

`gpt-5.5-pro` has no cache-read discount. The same 102.6M cache reads that cost $51 on standard
cost **$3,077** on pro. Use pro only for isolated hard problems; never as the daily driver.
Long agentic sessions are cache-read dominated, so cache pricing matters more than headline
input price.

### Google Play line items

- Play Console **$25 one-time**.
- New personal accounts: **12 testers for 14 continuous days** of closed testing before production.
- Low-end test device **$150-$400**.
- iOS later: **$99/year** plus a Mac.
- Privacy policy, data safety, content rating: time, not money.

### What a stronger model does not fix

Art direction and consistency, game-feel tuning, real-device QA, Play compliance, retention
design. A better brain shortens the code loop; those remain the schedule risk.

**Rule of thumb:** store-quality via vibe coding is **$2k-$5k cash and 300-400 hours** typical,
with **$1k-$2k of that being models**. The earlier $8k-$14k figure assumed commissioning most
art/audio and agency-style buffers; the earlier $30-$250 figure priced only the current
prototype.

**Running cost after launch:** Vercel Hobby is $0 but 100 GB/month and non-commercial only; Pro
$20/month gives 1 TB and commercial use. A Play release has no hosting bill; Google takes 15% of
the first $1M/year in revenue, then 30%.

## 10. The agent team

All agents are Markdown files in `.opencode/agents/`, model-agnostic by design: the role, permissions, and output contract live in the prompt, and only the `model:` line names a brain. Any capable model can run any role.

| Agent | Mode | Default model | Job |
| --- | --- | --- | --- |
| `feedback` | primary | `opencode/flint-40b-free#high` | User intake; rewrites requests into a brief, routes to orchestrator, summarises back. |
| `orchestrator` | all | `opencode/glm-5.3-flash-free#max` | Plans, decomposes, delegates to the four specialists, reviews evidence. Never edits or runs shell. |
| `thinker` | subagent | `opencode/glm-5.3-flash-free#max` | Read-only root-cause analysis and exact fix plans. |
| `asset-pipeline` | subagent | `opencode/nemotron-3.5-super-vl-free#high` | Generates and visually verifies 2D art through the AssetForge MCP. |
| `builder` | subagent | `opencode/deepseek-v4.1-flash-free#high` | Implements only the decided plan inside `khotwa/**`, with backups. |
| `tester` | subagent | `opencode/mimo-v2.6-flash-free` | Runs the game/browser, collects PASS/FAIL evidence, never fixes. |

Routing: feedback -> orchestrator -> thinker -> builder -> tester. Orchestrator passes `model` explicitly so cost and behaviour stay predictable.

**Model fallback:** if a configured model is unavailable, retry once, then substitute the nearest sibling (reasoning: glm -> deepseek; code: deepseek -> glm; vision: nemotron -> any vision-capable model; testing: mimo -> deepseek), and if none can be selected, omit `model` so the child inherits the parent session's model. Record the substitution in the report.

**Session-location rule (important):** project agents, skills, and MCP servers are discovered from the **session's location directory**, not from the shell's working directory. A session opened at `C:\Users\Qebaa` sees only built-in agents; a session opened at `C:\Users\Qebaa\Projects\Khotwa-Game` sees the team above plus the `memory`, `assetforge`, and `playwright` MCP servers. If the team looks missing, move the session into the project root.

## 11. Testing playbook

- Local serve: `python -m http.server 8900` inside `dist\web`, test `http://127.0.0.1:8900/` (never `file://`).
- Tools in `C:\Users\Qebaa\Projects\_tools\`: `mobile_suite.py <url>` (four viewports: 844x390, 915x412, 390x844, 412x915), `parse_result.py`, `webkit_confirm.py`, `start_keys.py`, `hud_test.py`, `latency_test.py`, `live_load.py`.
- Screenshots go to `C:\Users\Qebaa\Projects\_shots\`.
- Minimum regression: boot, rotate gate in portrait, tap-start, score advances, pause holds, resume continues, game over at zero health, revive question with 4 answers and countdown, restart works.
- Known environment noise: this machine intermittently throws `net::ERR_SSL_PROTOCOL_ERROR` against Vercel; retry once before calling it a bug.

## 12. Known risks and limits

- **Boot weight:** ~20 s first boot on an iPhone-class WebKit device because of the 37.7 MB wasm; a transient pack fetch can fail on flaky networks (the page has a Retry button). Reducing this is the biggest UX win available.
- **Content depth:** only 10 questions; repeat play exposes them quickly.
- **Commercial use:** Vercel Hobby is non-commercial; monetising requires Pro ($20/mo) or another host.
- **Free models:** availability can change; the fallback policy above keeps the team running but quality varies by brain.
- **Binary verification:** compare `.pck`/`.wasm` with `cmd /c "git show origin/web-build:index.pck > file"`; PowerShell `>` corrupts binaries.
- **Untracked generated asset:** `khotwa/assets/generated/sprites/smoke-coin.jpg` is not in git, so a CI build omits it. Add it deliberately if it should ship.
- **Evidence rule:** never claim a change works without tester evidence; never hand-edit `dist/web` or `web-build`.
