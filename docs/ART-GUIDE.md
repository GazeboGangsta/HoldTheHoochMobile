# Hold the Hooch Mobile — Art Guide

Replacement art specs for all visual assets. Drop SVGs into `assets/svg/` (raster fallbacks into `assets/images/`) with the exact filenames listed below. No code changes needed — the engine reads each file at startup.

## Current character sprites

**As of 2026-04-21 Gurgles is drawn from a derivative of the `no_hat_gnome` frames in the purchased *Gnomes Mega Character Pack* (Game Developer Studio, commercial licence per clause 4.1 of the GDN terms).** See [ART-PACK-INVENTORY.md](ART-PACK-INVENTORY.md) for the full pack inventory and the per-animation file layout.

- The pack's original character holds a wooden staff in his lead hand. This is intentionally kept in our build — it reframes Gurgles as "druid brewer with walking staff + magically-floating tankard" without requiring per-frame edits.
- The tankard remains a separate floating `SvgComponent` overlay (`assets/svg/hooch.svg`), rotated per-frame by `balance.tilt` — rendering logic in [lib/components/gurgles.dart](../lib/components/gurgles.dart).
- Asset-regeneration pipeline: extract the raw pack into `art-source/gnomes/` (gitignored), then run `dart run tools/build_gurgles_sprites.dart`. Output lands in `assets/images/gurgles/<anim>/` and is consumed at runtime via Flame's `Sprite.load` + `SpriteAnimation.spriteList`.

The original briefs below describe the aspirational art direction from before the pack was purchased. They're retained as reference for future hand-drawn polish passes (e.g. if we ever commission an original run-cycle).

## Current backdrop art

**As of 2026-04-21 the game's parallax backdrop is the free "Pine Hills" pack from [myaumya.itch.io](https://myaumya.itch.io/pine-hills-background).** Licensed for commercial use + modification; redistribution not allowed. See [assets/third_party/pine_hills/LICENSE.txt](../assets/third_party/pine_hills/LICENSE.txt). The pack ships 14 pixel-art PNG layers at 320×180; we use 13 of them (front_rocks skipped) rendered upscaled with `FilterQuality.none` for a crisp retro look.

Layer allocation + speed factors are documented in [lib/scenes/game_scene.dart](../lib/scenes/game_scene.dart) and the plan at [docs/superpowers/plans/2026-04-21-pine-hills-parallax.md](superpowers/plans/2026-04-21-pine-hills-parallax.md).

The deliberate pixel-art-background / smooth-cartoon-character hybrid style is a known aesthetic (Celeste, Hyper Light Drifter). If we ever commission custom parallax art later, the `RasterParallaxLayer` + `CloudDrift` components already handle arbitrary PNGs — drop new images in and tune the speed factors.

A visual iteration tool for this pack lives at [tools/pine-hills-preview.html](../tools/pine-hills-preview.html) — open it in a browser to tune layer order/position/speed live and copy-paste the resulting Dart config back into `game_scene.dart`.

## Unused asset pack: Forest Sprites

An alternative free pack from itch.io (`assets/third_party/forest_sprites/`) is staged on disk but not wired in — lighter (5 layers), daylight palette, higher per-tile resolution (500×300). Kept as a potential theme option for V2. License bundled: commercial OK, modify OK, no redistribution. See [assets/third_party/forest_sprites/LICENSE.txt](../assets/third_party/forest_sprites/LICENSE.txt).

## Current app icon

`assets/images/icon-source.png` (4267×4267 RGB) is the master for the in-store app icon. Regenerate platform-specific icons with:

```bash
dart run flutter_launcher_icons
```

The config block is in `pubspec.yaml` under `flutter_launcher_icons:`. Android uses a simple square icon at `@mipmap/launcher_icon` (non-adaptive for V1). iOS AppIcon.appiconset contains all sizes including the 1024×1024 App Store version with alpha stripped.

## Style

Flat/minimal SVG in the same visual language as the web game at [gurgles.beer](https://gurgles.beer). Clean geometric shapes, bold saturated colours, modern indie game feel. Think "old Newgrounds flash game from 2005, but crisper". Gurgles should be instantly recognisable alongside his web-game twin.

**Mobile-specific style notes:**
- Portrait orientation: layouts are tall, not wide.
- Reference canvas is **1080 × 1920** (logical pixels). Design elements to hold up at up to **3× density** (final pixel output ~1440 × 3120).
- Backdrop is now a **dusk/night** scene (dark navy → purple sky gradient). Avoid pure sky-blue hero colours — they clash with the backdrop.
- Silhouettes read first. Bold outlines, generous internal contrast.

## What's already in the repo

The web game's art has been pulled into `assets/svg/` as a starting point. You can replace any of them by dropping in a new file with the same name; the code reads by filename. The files currently present:

`gurgles.svg`, `gurgles-jump.svg`, `hooch.svg`, `root.svg`, `rock.svg`, `mushroom.svg`, `log.svg`, `herb.svg`, `hops.svg`, `potion.svg`, `bg-mountains.svg`, `bg-trees.svg`, `bg-ground.svg`, `banner.svg`.

The mobile app upgrades and additions below are what's still needed.

---

## Character: Gurgles the Druid Brewer Gnome

### `gurgles-run-1.svg` through `gurgles-run-6.svg` — Run cycle

| Property | Value |
|----------|-------|
| **Filenames** | `assets/svg/gurgles-run-1.svg` … `gurgles-run-6.svg` |
| **viewBox** | `0 0 64 80` (each frame) |
| **Rendered size** | 64 × 80 px |
| **Frame rate** | 12 fps (one loop cycle ≈ 0.5 s) |

**Design notes:**
- Same Gurgles as the web game — pointy red hat, round face, bushy silver beard, green tunic, brown belt, brown boots. Arms always raised above head (holding the hooch, which is a separate sprite).
- Six frames covering one full stride. Mirror or reuse frames if it makes the cycle smoother (e.g. 1→2→3→4→5→6→5→4→3→2 = 10 apparent frames from 6 art frames).
- Upper body should stay relatively still (arms up holding hooch) — only legs, feet, and a subtle beard bob animate.
- Hands should stay pinned at roughly the same (x, y) across frames so the tankard doesn't appear to bob out of his grip.

### `gurgles-jump.svg` — Jumping pose (already present)

| Property | Value |
|----------|-------|
| **Filename** | `assets/svg/gurgles-jump.svg` |
| **viewBox** | `0 0 64 70` |
| **Rendered size** | 64 × 70 px |

**Design notes:** web game version is usable. Optional upgrade: three variants for rising / peak / falling — `gurgles-jump-up.svg`, `gurgles-jump-peak.svg`, `gurgles-jump-down.svg`. Not required for V1.

### `gurgles-hurt.svg` — Game over pose

| Property | Value |
|----------|-------|
| **Filename** | `assets/svg/gurgles-hurt.svg` |
| **viewBox** | `0 0 64 80` |
| **Rendered size** | 64 × 80 px |

**Design notes:**
- Gurgles after losing the hooch. Arms down, empty-handed, dejected slump.
- Same character, same outfit. One frame, no animation needed.
- Shown on the GameOver overlay above the score.

---

## The Hooch

### `hooch.svg` — Big Tankard (already present)

| Property | Value |
|----------|-------|
| **Filename** | `assets/svg/hooch.svg` |
| **viewBox** | `0 0 40 36` |
| **Rendered size** | 40 × 36 px |

**Design notes:** web game version is usable. Overflowing foam, amber liquid, wooden/metal tankard. The mobile build **rotates** this sprite around its bottom-center based on `balance.tilt` — anchor visual weight low so the rotation looks natural.

**Optional upgrade:** `hooch-empty.svg` — the spilled version shown on the game-over screen (tipped, empty, dripping).

### `hooch-splash.svg` — Spill particle

| Property | Value |
|----------|-------|
| **Filename** | `assets/svg/hooch-splash.svg` |
| **viewBox** | `0 0 32 32` |
| **Rendered size** | 32 × 32 px |

**Design notes:**
- Small droplet / splash shape in hooch amber (#D4A017) with cream foam highlights (#FFF9C4).
- Emitted as particles when tilt exceeds ~70% (i.e. whenever the spill meter is filling).
- Several of these will be instantiated at random velocities — keep it simple.

---

## Obstacles

Already in the repo: `root.svg`, `rock.svg`, `mushroom.svg`, `log.svg`. Web-game versions are usable but feel free to replace with tighter mobile variants.

Mobile-specific guidance:
- **Silhouettes must read at small sizes** — obstacles occupy ~7–15% of screen width. Thin or fiddly shapes lose clarity on a phone.
- Ground contact edge should be flat and opaque — the collision hitbox uses the bottom edge.

---

## Collectibles

Already in the repo: `herb.svg`, `hops.svg`, `potion.svg`. Web-game versions are usable.

**Optional upgrade — sparkle particle:**

### `sparkle.svg`

| Property | Value |
|----------|-------|
| **Filename** | `assets/svg/sparkle.svg` |
| **viewBox** | `0 0 24 24` |
| **Rendered size** | 24 × 24 px |

4- or 8-point star / sparkle. Emitted when Gurgles picks up a collectible. White-yellow, semi-transparent.

---

## Backgrounds

All backgrounds scroll horizontally in a loop (tiled side-by-side). They must **tile seamlessly** — the left edge must match the right edge.

Mobile already uses the web game's `bg-mountains.svg` and `bg-trees.svg`. The mobile build is **portrait**, so these SVGs stretch vertically more than they did on the web. The web versions hold up, but here's the mobile-optimised spec if you want to redraw:

### `bg-mountains.svg` — Far Background

| Property | Value |
|----------|-------|
| **Filename** | `assets/svg/bg-mountains.svg` |
| **viewBox** | `0 0 1600 800` *(taller than web's 1600×600)* |
| **Tile behaviour** | Horizontal tile only, at 0.15× scroll |

**Mobile-specific notes:**
- Compose so the interesting mountain silhouettes live in the **bottom 50%** of the SVG. The top 50% is sky.
- Sky gradient should start at `#1A1A3E` (dark navy) at the top and drift into `#2D1B69` (purple) lower. This matches the mobile's global background colour so there's no horizontal seam where the layer starts.
- Optional: stars, moon, distant aurora. Keep it atmospheric and low-contrast.

### `bg-trees.svg` — Mid Background

| Property | Value |
|----------|-------|
| **Filename** | `assets/svg/bg-trees.svg` |
| **viewBox** | `0 0 1600 600` |
| **Tile behaviour** | Horizontal tile only, at 0.45× scroll |

**Mobile-specific notes:**
- Transparent background — draws on top of the mountains layer.
- Tree **trunks must extend past the bottom of the viewBox** so there's no gap between the trees and the ground tile.
- 6–10 trees, varied heights.

### `bg-ground.svg` — Ground Strip

| Property | Value |
|----------|-------|
| **Filename** | `assets/svg/bg-ground.svg` |
| **viewBox** | `0 0 1600 200` |
| **Tile behaviour** | Horizontal tile only, at 1.0× scroll |

**Mobile-specific notes:**
- Web version is usable. Grass top strip + dirt below.
- Gurgles' feet sit on the TOP edge of this asset (i.e. `y = 0` of the viewBox is the ground line).

### `bg-sky-stars.svg` — Optional sky overlay

| Property | Value |
|----------|-------|
| **Filename** | `assets/svg/bg-sky-stars.svg` |
| **viewBox** | `0 0 1600 400` |
| **Rendered size** | Full screen width, top 40% of screen |
| **Tile behaviour** | Horizontal tile, at 0.05× scroll (barely moves) |

**Design notes:**
- Sparse star field, a crescent moon, optional wispy cloud.
- Transparent background — composites over the global dark-navy backdrop.
- Not required for V1 but will dramatically improve how "finished" the upper half of the screen feels.

---

## UI

### `logo.svg` — Title treatment

| Property | Value |
|----------|-------|
| **Filename** | `assets/svg/logo.svg` |
| **viewBox** | `0 0 720 320` |
| **Rendered size** | 720 × 320 px |

**Design notes:**
- "Hold the Hooch" wordmark with a bit of character — maybe a tiny Gurgles next to it, or a tankard integrated into a letterform.
- Warm/brewer's palette: amber + cream + wood-brown.
- Must read cleanly on the dark navy menu background. Add a subtle drop shadow or outline if needed.

### `spill-meter-frame.svg` and `spill-meter-fill.svg`

| Property | Value |
|----------|-------|
| **Filenames** | `assets/svg/spill-meter-frame.svg`, `assets/svg/spill-meter-fill.svg` |
| **viewBox** | `0 0 480 48` (frame), `0 0 472 40` (fill) |
| **Rendered size** | Scales to ~60% of screen width |

**Design notes:**
- Current implementation is code-drawn rectangles. Replacing with SVGs adds visual flair.
- **Frame:** a pill-shaped / wooden-banded outer container. Tankard-themed — brass or leather strap aesthetic.
- **Fill:** the fluid that grows inside the frame as tilt increases. Hooch-amber (#D4A017) with foam highlights.
- The fill is scaled horizontally in code — design it so horizontal stretching doesn't ruin the look.

### `btn-retry.svg` and `btn-menu.svg`

| Property | Value |
|----------|-------|
| **Filenames** | `assets/svg/btn-retry.svg`, `assets/svg/btn-menu.svg` |
| **viewBox** | `0 0 320 96` |
| **Rendered size** | 320 × 96 px |

**Design notes:**
- Wooden-plank or tankard-banded button backgrounds.
- Typography readable at both 1× and 3× density.
- Consistent with the warm brewer aesthetic.

### `tap-hint.svg` and `drag-hint.svg` — Tutorial overlays

| Property | Value |
|----------|-------|
| **Filename** | `assets/svg/tap-hint.svg` |
| **viewBox** | `0 0 128 128` |
| **Rendered size** | 128 × 128 px |

| Property | Value |
|----------|-------|
| **Filename** | `assets/svg/drag-hint.svg` |
| **viewBox** | `0 0 256 128` |
| **Rendered size** | 256 × 128 px |

**Design notes:**
- Shown the first 1–2 seconds of the first run only.
- **Tap hint:** stylised finger tapping, pulsing animation drawn in-engine. Simple silhouette is fine.
- **Drag hint:** two horizontal arrows or a finger drag gesture, hinting at the left-side drag-to-balance control.

---

## App store / platform

### `icon-source.svg` — Master app icon

| Property | Value |
|----------|-------|
| **Filename** | `assets/svg/icon-source.svg` |
| **viewBox** | `0 0 1024 1024` |
| **Rendered size** | 1024 × 1024 px |

**Design notes:**
- Gurgles' face with the tankard above his head, centred.
- **Safe zone:** all important elements within the central 80% (stores crop the outer 10% for rounded masks).
- Solid opaque background — stores reject transparent icons. Warm amber or wood-brown backdrop recommended.
- No text. The name is displayed by the OS below the icon.

### `icon-android-fg.svg` and `icon-android-bg.svg` — Adaptive icon

| Property | Value |
|----------|-------|
| **Filenames** | `assets/svg/icon-android-fg.svg`, `assets/svg/icon-android-bg.svg` |
| **viewBox** | `0 0 1080 1080` (both) |

**Design notes:**
- Android adaptive icons: OS composites foreground over background, then applies a launcher-chosen mask.
- **Foreground:** Gurgles + tankard, with transparent surroundings. Keep all content within the central 66% (720 × 720 centred).
- **Background:** solid colour or subtle pattern. No critical content.

### `splash.svg` — Splash screen

| Property | Value |
|----------|-------|
| **Filename** | `assets/svg/splash.svg` |
| **viewBox** | `0 0 1242 2688` (iPhone Pro Max reference) |
| **Rendered size** | Scales to device |

**Design notes:**
- Full-screen, portrait.
- Dark navy backdrop (`#1A1A3E`) matching the game background.
- Logo + Gurgles centred.
- Shown for ~1 second during app launch.

### `feature-graphic.png` — Play Store banner

| Property | Value |
|----------|-------|
| **Filename** | `assets/images/feature-graphic.png` |
| **Rendered size** | 1024 × 500 px (raster, landscape) |

**Design notes:**
- Play Store's feature banner shown at the top of the listing page.
- Gurgles mid-run, full composition with parallax, logo prominent.
- Must work at very small sizes too — text needs to be chunky.

### `screenshot-*.png` — Store screenshots

**Required formats (per store):**
- Google Play: 1080 × 1920 (portrait), 2–8 shots
- App Store: 1290 × 2796 (iPhone 6.7"), 3–10 shots

**Suggested shots:**
1. Title screen with logo prominent
2. Mid-run with obstacle approaching
3. Mid-run with tankard tilted, spill meter visible
4. Mid-jump clearing a log
5. Collecting a potion
6. Game over with high score

---

## General SVG requirements

1. **Format:** plain SVG (no embedded rasters, no external references)
2. **Namespace:** `xmlns="http://www.w3.org/2000/svg"`
3. **viewBox:** must match the exact values listed — the engine loads them at specific pixel sizes
4. **Width/height attributes:** include them matching the viewBox dimensions
5. **No animations:** the engine handles all animation via code. Frame-by-frame cycles live in separate SVG files
6. **Transparency:** transparent backgrounds (no background rectangle) — the engine composites layers
7. **Colours:** bold, saturated. The game backdrop is **dark navy (#1A1A3E)** — avoid pure dark navy for character/obstacle art
8. **File size:** keep SVGs lean — avoid unnecessary path precision, minimise nested groups

## Color palette reference

| Element | Primary | Secondary |
|---------|---------|-----------|
| Backdrop (sky) | #1A1A3E (dark navy) | #2D1B69 (purple) |
| Gurgles' hat | #C0392B (red) | |
| Gurgles' skin | #F5CBA7 (peach) | |
| Gurgles' tunic | #27AE60 (green) | |
| Gurgles' beard | #BDC3C7 (silver) | |
| Gurgles' boots | #5D4037 (brown) | #8B6914 (pants) |
| Hooch liquid | #D4A017 (amber) | |
| Hooch foam | #FFF9C4 (cream) | |
| Hooch tankard | #8B4513 (wood) | |
| Obstacles | #5D4037–#8D6E63 (browns) | #78909C (rock grey) |
| Herbs | #27AE60, #2ECC71 (greens) | |
| Hops | #F1C40F, #F39C12 (golds) | |
| Potion | #3498DB (blue), #9B59B6 (purple) | |
| Trees | #1B5E20–#388E3C (dark greens) | |
| Ground grass | #4CAF50, #66BB6A | |
| Ground dirt | #5D4037 | |
| UI accent | #D4A744 (brass/gold) | |

## Delivery

- Drop SVGs into `assets/svg/` with the exact filename listed.
- Drop raster outputs (PNGs for store assets, icons) into `assets/images/`.
- If you're doing icons + screenshots, PR or zip them — they need to be referenced from `android/app/src/main/res/` and `ios/Runner/Assets.xcassets/` which requires small code changes.
- No PR required for in-game SVGs — the engine picks them up automatically next build.
