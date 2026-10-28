# Khotwa

Khotwa (Break Free) is a 2D endless runner built in Godot 4.7.

## Play

| Purpose | URL |
| --- | --- |
| Production (current build) | https://web-seven-iota-32.vercel.app/ |
| Preview (same build) | https://khotwa-preview.vercel.app/ |

Both serve the public web export, so they are playable from any phone, tablet or desktop
browser — no local install needed. The game runs landscape only and asks you to rotate.

## Open the project

Open the `khotwa` folder in **Godot 4.7** and run the main scene. The game is
authored at 1920×1080 and letterboxed, so any screen size works.

## Build the web version

The web build is produced only through Godot's export pipeline — never edit `dist/web` by hand.

```powershell
godot --headless --path khotwa --export-release "Web" ..\dist\web\index.html
```

The `Web` preset is configured for **Compatibility / WebGL 2** with **threads off**, which is
what makes it work on mobile Safari and Android without cross-origin isolation headers.

`dist/` is gitignored: this repository holds the source, the hosting project holds the
built artifacts.

## Deploy

`dist/web` is a plain static site. From inside `dist/web`:

```powershell
vercel deploy --prod --yes --non-interactive
```

The preview and production Vercel projects are both under the `port-nova` team.
