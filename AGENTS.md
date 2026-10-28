# Khotwa - working instructions

## Read first

- `docs/PROJECT.md` - what the game is, how it plays, architecture, costs.
- `docs/BUILD-PLAN.md` - milestones, gates, model routing, art pipeline, economy scope.
- `.opencode/skills/khotwa-game/SKILL.md` - the same context for agents.

## Non-negotiables

- Godot 4.7.2, **Compatibility / WebGL 2**, **threads off**, 1920x1080 design space, landscape only.
- Never hand-edit `dist/web` or the `web-build` branch. They are generated output.
- Never hand-edit the exported `index.html` / `index.js`; use the Godot export pipeline.
- Back up before destructive edits. No force-push to `main`.
- Do not claim a change works without evidence from a real run.

## Deploy

Push to `main` is the deploy. CI exports the game in about 30 seconds, force-pushes the artifact to
the generated `web-build` branch, and Vercel publishes https://khotwa-preview.vercel.app/.
See `README.md`.

## Verification

- Serve `dist/web` over local HTTP (`python -m http.server 8900`), never `file://`.
- `C:\Users\Qebaa\Projects\_tools\mobile_suite.py <url>` runs four mobile viewports.
- Compare binaries with `cmd /c "git show origin/web-build:index.pck > file"`; PowerShell
  redirection corrupts binaries.

## Audience and compliance

- Declared **13+**. Never let the art or store listing signal "for young children" - it would
  trigger Play Families policy, which removes personalised ads and most analytics.
- No personal data collected from under-13s. Prefer anonymous, aggregate metrics.
- Money in, cosmetics out: no currency that can be cashed out or traded between players.

## Agent team

`feedback` -> `orchestrator` -> `thinker` / `asset-pipeline` / `builder` / `tester`, defined in
`.opencode/agents/`. Project agents, skills and MCP servers load from the **session location**, so
open sessions at the project root.
