# Asset Pipeline Rules

## SpriteHatch / Chutes Prompt Requirements
When calling SpriteHatch or Chutes, always specify:
- "2D game sprite, transparent background, consistent character identity across frames."
- For animations, request exactly 4-8 frames per loop.
- Save all generated assets to `assets/sprites/` and `assets/ui/`.
- Return absolute file paths in the format `ASSET_READY: /path/to/file.png`.

## Frame Count
- Idle animations: 4 frames minimum, 8 frames maximum.
- Action animations (run, jump): 6-8 frames.
- UI icon animations: 4 frames.
- All frames must share the same canvas size and hotspot.

## Asset Naming
- Follow the `asset-naming` skill convention: `<category>_<subject>_<variant>_<size>.<ext>`
- category: `spr` (sprite), `ui` (interface icon), `bg` (background)
- subject: lowercase noun, `snake_case`
- variant: state or direction, zero-padded animation frames: `_01`, `_02`, etc.
- size: actual pixel size, not a scale label

## Consistency Checks (run after each batch)
- Same outline weight across all assets.
- Same light direction (top-left default).
- Same palette roles assigned.
- Same camera angle and scale.
- No accidental photorealism or 3D render look in a flat-vector batch.
- All transparent backgrounds actually have alpha channel (no accidental white/black mats).