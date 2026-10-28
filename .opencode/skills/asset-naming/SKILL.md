---
name: Asset Naming
description: Naming, folder, manifest, and hand-off conventions for sprites, backgrounds, UI icons, and other generated game assets
---

# Asset Naming

Use this skill whenever an asset is generated, imported, renamed, or handed from the Asset Pipeline to the Builder.

## File name pattern

```text
<category>_<subject>_<variant>_<size>.<ext>
```

- `category`: `spr` (sprite), `bg` (background), `ui` (interface icon), `fx` (effect), `tile` (tile/track piece).
- `subject`: lowercase noun, `snake_case`: `runner`, `barrier`, `coin`, `heart`, `pause`.
- `variant`: state or direction: `idle`, `run_01`, `run_02`, `jump`, `hurt`, `front`, `side`, `day`, `night`.
- `size`: `64`, `128`, `256`, `512`, or `1920x1080`. Use the actual pixel size, not a scale label.
- `ext`: `.png`, `.webp`, `.jpg`, `.svg`.

Examples:

```text
spr_runner_run_01_256.png
spr_barrier_side_256.png
spr_coin_spin_01_128.png
bg_desert_day_1920x1080.webp
ui_heart_full_128.png
```

Rules:

- Lowercase only. No spaces, accents, Arabic letters, parentheses, or version words in the filename.
- Use `_` between fields and `-` only inside a field when needed.
- Zero-pad animation frames: `_01`, `_02`, ... `_10`.
- Never reuse an old name for different art. Add `_v2` only when replacing an existing asset intentionally, and record why in the manifest.

## Folders

```text
khotwa/assets/
├── generated/
│   ├── sprites/
│   ├── backgrounds/
│   └── ui/
├── fonts/
└── ...existing original assets...
```

- Generated assets go only under `khotwa/assets/generated/<kind>/`.
- Never overwrite or rename original assets under `khotwa/assets/` without an explicit instruction.
- The AssetForge MCP adds a numeric suffix when a name already exists. Keep that suffix; do not rename the file afterwards.

## Manifest

Every batch must return a manifest row:

| Field | Example |
| --- | --- |
| `file` | `spr_coin_spin_01_128.png` |
| `absolute_path` | `C:\...\khotwa\assets\generated\sprites\spr_coin_spin_01_128.png` |
| `category` | `spr` |
| `subject` | `coin` |
| `variant` | `spin_01` |
| `size` | `128x128` |
| `purpose` | `coin pickup, frame 1 of 4` |
| `prompt` | exact prompt used |
| `seed` | `42` |
| `style` | `flat-vector` |
| `status` | `accepted` / `rejected` |

Also include a `manifest.json` next to the batch when more than three assets are generated:

```json
{
  "batch": "coin-spin",
  "created_at": "2026-10-28T00:00:00Z",
  "assets": [
    {
      "file": "spr_coin_spin_01_128.png",
      "size": [128, 128],
      "purpose": "coin pickup, frame 1 of 4",
      "prompt": "...",
      "seed": 42
    }
  ]
}
```

## Hand-off rules

- The Asset Pipeline returns absolute paths, dimensions, and the manifest row. It does not edit code.
- The Builder references the exact path. If the path does not exist, the Builder stops and reports it.
- The Tester verifies the asset is actually visible in-game at the expected scale and does not report a missing texture as a pass.
- Keep generated assets out of `dist/`; the export pipeline copies them.

## Compatibility

- PNG or WebP for 2D art. JPEG only for opaque backgrounds, never for sprites that need transparency.
- sRGB color space. No embedded color profiles.
- Avoid filenames that differ only by case; Windows and Android are case-insensitive in different ways.
- Keep each file under 4 MB; backgrounds under 2 MB when possible.
