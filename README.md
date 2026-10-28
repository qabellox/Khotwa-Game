# Khotwa

Khotwa (خطوة, "a step") is a 2D endless runner built in **Godot 4.7.2**: an Arabic
anti-drug and addiction-awareness game exported for the web.

## Play

**https://khotwa-preview.vercel.app/**

This is the only hosted copy. It serves the public web export, so it is playable from any
phone, tablet or desktop browser - no local install needed. The game runs landscape only and
asks you to rotate.

You run through three lanes, dodge drugs and junk food, collect coins, fruit and healthy
items, and revive after death only by answering an Arabic awareness question correctly
within 15 seconds.

## Project context

- `docs/PROJECT.md` - what the game is, how it plays, architecture, costs and the agent team.
- `.opencode/skills/khotwa-game/SKILL.md` - the same context for AI agents.
- `.opencode/agents/` - the agent definitions (`feedback`, `orchestrator`, `thinker`,
  `asset-pipeline`, `builder`, `tester`).

## Open the project

Open the `khotwa` folder in **Godot 4.7** and run the main scene. The game is authored at
1920x1080 and letterboxed, so any screen size works.

## Build the web version

The web build is produced only through Godot's export pipeline - never edit `dist/web` by hand.

```powershell
godot --headless --path khotwa --export-release "Web" ..\dist\web\index.html
```

The `Web` preset is configured for **Compatibility / WebGL 2** with **threads off**, which is
what makes it work on mobile Safari and Android without cross-origin isolation headers.

`dist/` is gitignored: this repository holds the source, the hosting project holds the
built artifacts.

## Deploy

**Just push to `main`.** Nothing else is required, from any device:

1. A push to `main` starts the **Web build** workflow (`.github/workflows/web-build.yml`).
2. It exports the game with Godot 4.7.2 and force-pushes the result to the `web-build` branch.
3. Vercel watches `web-build` as its production branch and deploys it to
   https://khotwa-preview.vercel.app/ automatically.

You never touch `web-build`; it is generated output. `main` stays clean source.

Notes:

- CI uses `tools/godot-templates/web_nothreads_release.zip` so it never downloads the full
  1.2 GB export-template archive.
- A build takes about 30 seconds. Progress: https://github.com/qabellox/Khotwa-Game/actions
- To rebuild without changing code, run the workflow manually from the Actions tab.
- Manual deploy from `dist/web` still works for emergencies: `vercel deploy --prod`.
