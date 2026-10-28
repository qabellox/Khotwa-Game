---
name: Mobile Performance
description: Rules for smooth mobile-browser rendering in the Khotwa WebGL2 build, including texture budget, draw calls, DPR caps, audio unlock, and low-end test procedure
---

# Mobile Performance

Use this skill for any change that touches rendering, textures, UI layers, input, audio, or the web export.

## Frame budget

- Target 60 fps on a mid-range Android phone. Budget 16.6 ms per frame; keep the main thread under 10 ms.
- Target a p95 frame time under 20 ms at 1.5 DPR on a 390x844 viewport. If you cannot measure p95, report the method and the raw samples.
- A stable 30 fps is better than a stuttering 60 fps. Do not add work that causes long frames.

## Rendering

- Keep the renderer on Compatibility / WebGL 2. Threads stay off; never require SharedArrayBuffer or cross-origin isolation.
- Cap device pixel ratio in the HTML shell: 2.0 desktop, 1.5 on `(pointer: coarse)`. Do not render the full-screen canvas at 3x/4x DPR.
- Keep draw calls under 100 for a 2D scene. Batch sprites that share a texture; avoid one material per object.
- Atlas small sprites. Avoid many tiny textures and per-frame texture swaps.
- Use compressed textures where supported; for 2D UI/PNG art, prefer WebP or optimized PNG and avoid 4K source images.
- Avoid full-screen transparent overdraw. The HUD should be one CanvasLayer, not many stacked full-screen panels.
- No per-frame allocations in `_process`: reuse vectors, arrays, and strings. Pool obstacles, pickups, and coin particles.
- Preload audio and textures before the run starts. Do not decode large images synchronously on the first frame.
- Pause or hide off-screen work; do not process spawners or animations that cannot be seen.

## Input

- Respond to the first short tap; never require a double tap.
- Unlock audio on the first user gesture (tap/click/key). If audio is locked, the game must still start.
- Use `touch-action: manipulation` and disable double-tap zoom on the canvas.
- Keep touch targets at least 72 px tall in the 1920x1080 design space.

## Web export

- Do not hand-edit `dist/web/index.html` or `index.js`; use the Godot export pipeline.
- Verify the export still has threads off, the custom shell, and the 1920x1080 viewport.
- Test the exported `dist/web` over local HTTP (`python -m http.server 8900`), not `file://`.
- Cache headers must allow revalidation (`max-age=0, must-revalidate`); do not add a query-string cache buster to the canonical URL.
- Large downloads can fail mid-transfer on flaky networks. A single reload is an acceptable recovery; do not mask it as a game bug.

## Test procedure

1. Serve `dist/web` at `http://127.0.0.1:8900/`.
2. Emulate a mobile viewport (390x844 and 412x915), DPR 2.5, touch enabled.
3. Record: load time, first interactive frame, FPS during a run, p95 frame time, long tasks, console errors, failed requests.
4. Throttle CPU 6x and retest the start; the game must remain playable and the lane slide must stay time-based.
5. Check memory growth over a 60-second run; pool/reuse must prevent unbounded growth.
6. Report raw numbers and the method. Never guess.

## Red flags

- A full-screen shader per frame.
- Textures larger than 2048x2048.
- Per-frame `instantiate`/`free` of nodes.
- `await` on asset loads inside `_process`.
- A HUD that redraws every frame when nothing changed.
- Input handlers that only listen for `click` (300 ms delay) instead of pointer/touch down.
