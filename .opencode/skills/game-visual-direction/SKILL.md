# Game Visual Direction

## Palette Roles
Define a fixed palette before producing assets. Every color must have a role:
- `bg_far` - lowest contrast, coolest, most desaturated (distant background)
- `bg_mid` - mid contrast, supports the horizon
- `track` - the play surface; highest local contrast where the player reads danger
- `hero` - the player character; one saturated accent reserved for it
- `reward` - coins/pickups; warm gold or bright cyan, used sparingly
- `danger` - obstacles; red-orange, never the same hue as `reward`
- `ui` - panels and text; neutral dark panels with one accent border
- `ink` - outlines and shadows; a dark tint of the local color, not pure black

## Shape Language
- Readable silhouette at 64x64. If unclear when downscaled, redesign the shape.
- One consistent outline weight per batch (usually 2 px at 256 px).
- One light direction per batch; top-left is the default.
- Flat fills plus one shadow shape and one highlight shape. Do not add noisy texture to every surface.
- Characters face the direction of travel (right for this runner) unless the brief says otherwise.
- No text, logos, watermarks, or UI frames baked into sprites.

## Pixel Ratio and Scaling
- Generate at the final display size or a clean integer multiple: 64, 128, 256, 512.
- Never scale a sprite by a fractional factor in the game; use nearest filtering for pixel art and linear filtering for painted art, and keep it consistent.
- Clamp device pixel ratio: 2.0 on desktop, 1.5 on coarse-pointer mobile. Never render at 3x/4x DPR for a full-screen canvas.
- Keep the 1920x1080 design space. Do not bake device-specific sizes into assets.

## Parallax and Depth
- 3 to 5 layers, ordered by depth.
- Far layers: low contrast, low detail, slow scroll, slightly cooler.
- Near layers: higher contrast, faster scroll, warmer.
- The horizon line must stay stable during a run; no layer should jump or pop.
- Do not put pure black or pure white in a background layer; reserve maximum contrast for gameplay objects.
- Ground/track layers must not compete with obstacles: keep their edges softer than the danger color.

## UI and HUD
- Flat panels, 2 px border, one accent color, high contrast text.
- Arabic text: Tahoma or Arial, right-to-left, never stretched or mirrored.
- Buttons: minimum 72 px tall in the 1920x1080 space, clear pressed state, no hover-only affordance.
- Do not rely on color alone for health/danger; pair it with a shape or position change.

## Asset Generation Prompts
Include all of these in the prompt:
1. Subject and purpose.
2. View and pose.
3. Silhouette requirement ("readable at 64 px").
4. Palette roles or exact colors.
5. Background treatment (`green-screen`, `white`, or `auto`).
6. "No text, no watermark, no UI frame, one subject only."

After generation, inspect the image with a vision-capable model. Reject if the subject is duplicated, cropped, includes text, or has a different outline weight from the batch.

## Consistency Checklist
- Same outline weight across the batch.
- Same light direction.
- Same palette roles.
- Same camera angle and scale.
- Same background treatment.
- No accidental photorealism or 3D render look in a flat-vector batch.