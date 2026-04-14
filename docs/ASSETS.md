# Asset Requirements — HoldTheHooch Mobile V1

All art is **SVG-first** (drop into `assets/svg/`, referenced by filename). Raster fallbacks go in `assets/images/` at `@1x`, `@2x`, `@3x`. Style: flat/minimal, same visual language as the web game.

Target canvas reference: **1080×1920 (portrait)**. Design elements to look crisp at 3x density (up to ~1440×3120).

## Character

| Asset | File | Notes |
|-------|------|-------|
| Gurgles — run cycle | `gurgles_run_1..8.svg` | 8 frames, 256×256 each. Body runs, arms hold tankard overhead. |
| Gurgles — jump (rising) | `gurgles_jump_up.svg` | 256×256 |
| Gurgles — jump (peak) | `gurgles_jump_peak.svg` | 256×256 |
| Gurgles — jump (falling) | `gurgles_jump_down.svg` | 256×256 |
| Gurgles — hurt/gameover | `gurgles_hurt.svg` | 256×256 |

## Hooch / tankard

| Asset | File | Notes |
|-------|------|-------|
| Tankard body | `hooch_tankard.svg` | 192×192. Rendered separately so it can be rotated around Gurgles' hands. |
| Hooch liquid surface | `hooch_liquid.svg` | 128×64. Ellipse that tilts with wobble. |
| Spill splash (particle) | `hooch_splash.svg` | 64×64. Triggered on game-over-by-spill. |

## Obstacles

| Asset | File | Size |
|-------|------|------|
| Root | `obstacle_root.svg` | 128×64 |
| Rock | `obstacle_rock.svg` | 128×128 |
| Mushroom cluster | `obstacle_mushrooms.svg` | 192×96 |
| Fallen log | `obstacle_log.svg` | 320×96 |

## Collectibles

| Asset | File | Size |
|-------|------|------|
| Herb | `collectible_herb.svg` | 64×64 |
| Golden hop | `collectible_hop.svg` | 64×64 |
| Potion bottle | `collectible_potion.svg` | 64×96 |

## Environment / parallax

Three parallax layers, each full-width tile (~2160×1920, tiles horizontally):

| Asset | File | Notes |
|-------|------|-------|
| Far layer — distant trees / mountains | `bg_far.svg` | Scrolls at 0.2x |
| Mid layer — closer forest silhouette | `bg_mid.svg` | Scrolls at 0.5x |
| Near layer — bushes, ferns | `bg_near.svg` | Scrolls at 0.8x |
| Ground tile | `ground_tile.svg` | 256×128, tiles horizontally, scrolls at 1.0x |

## UI

| Asset | File | Size |
|-------|------|------|
| Logo / title | `ui_logo.svg` | 720×320 |
| Spill meter frame | `ui_spill_frame.svg` | 480×64 |
| Spill meter fill | `ui_spill_fill.svg` | 472×56 (scales horizontally) |
| Jump button hint | `ui_tap_hint.svg` | 128×128 (only shown in tutorial overlay) |
| Drag hint arrows | `ui_drag_hint.svg` | 256×128 |
| Retry button | `ui_btn_retry.svg` | 320×96 |
| Menu button | `ui_btn_menu.svg` | 320×96 |

## App store / platform

| Asset | File | Size |
|-------|------|------|
| App icon | `icon_source.svg` | 1024×1024, no transparency, no rounded corners |
| Adaptive Android icon foreground | `icon_android_fg.svg` | 432×432 safe zone in 1080×1080 |
| Adaptive Android icon background | `icon_android_bg.svg` | 1080×1080 solid or pattern |
| Splash screen | `splash.svg` | 1242×2688 (largest iPhone) |
| Feature graphic (Play Store) | `feature_graphic.png` | 1024×500 raster |
| Screenshots | `screenshot_*.png` | Multiple, see store spec |

## Audio (optional for V1)

| Asset | File | Notes |
|-------|------|-------|
| Jump | `sfx_jump.wav` | Short, ~200ms |
| Land | `sfx_land.wav` | Short |
| Collect — herb | `sfx_collect_low.wav` | |
| Collect — hop | `sfx_collect_mid.wav` | |
| Collect — potion | `sfx_collect_high.wav` | |
| Spill tick | `sfx_spill.wav` | Loops while spilling |
| Game over | `sfx_gameover.wav` | |
| Background music | `bgm_forest.ogg` | Looping, ~60-90s |

## Naming / format rules

- Lowercase, underscore-separated filenames.
- SVG: viewBox set to the declared size above, no embedded raster.
- PNG raster fallbacks: PNG-24 with alpha, no interlacing.
- Audio: WAV for SFX, OGG Vorbis for music.
- All assets live under `assets/` and are declared in `pubspec.yaml`.
