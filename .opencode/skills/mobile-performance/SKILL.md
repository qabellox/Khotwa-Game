# Mobile Performance

## Texture Compression
- Enable both desktop and mobile texture formats (ETC2/ASTC for mobile, DXT for desktop).
- Keep texture memory under 64 MB total for low-end devices.
- Use square power-of-2 textures where possible; avoid non-square textures on mobile.

## Audio Autoplay
- Always include a "Tap to Start" screen to unlock audio context.
- Never auto-play BGM on page load; it will be muted by the browser.
- Provide a visible mute/unmute toggle in the HUD.

## Particle Count
- Reduce particle count by 50% on low-end devices.
- Use additive blending sparingly; it is expensive on mobile GPU.
- Cap the active particle count at 50 simultaneously.

## Game Loop
- Use `requestAnimationFrame` for the game loop; never `setInterval`.
- In `_process`, gate all logic behind `if game_manager.state == GameState.RUNNING`.
- Delta time scaling: cap maximum delta to prevent fast-forward on alt-tab.

## Render Scale
- Canvas size: 1920x1080 design space, stretch `canvas_items`, aspect `keep`.
- DPR cap: 2.0 on desktop, 1.5 on coarse-pointer mobile.
- Never render at 3x/4x DPR for a full-screen canvas.