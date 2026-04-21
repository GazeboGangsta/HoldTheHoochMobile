# Gnomes Mega Character Pack — Inventory

Received 2026-04-21. Source: `gnomes.zip` (67 MB archived, 86 MB expanded, 1736 files) from Game Developer Studio (Robert Brooks / gamedeveloperstudio.com). Extracted to [art-source/gnomes/](../art-source/gnomes/) — gitignored; only curated frames land in `assets/`.

## License (plain-English summary)

Non-exclusive, perpetual, commercial use permitted in derivative works (e.g. this game). Attribution not required. Modifications allowed. **Cannot** redistribute the raw assets, bundle in game templates for resale, sell as NFTs, or use outside of derivative works. Full terms in [art-source/gnomes/LICENSE/License.txt](../art-source/gnomes/LICENSE/License.txt). Purchase receipt is the single-licence-holder proof; store it somewhere safe.

Practical implication: **we can ship these frames baked into the APK/IPA**; users cannot extract them from a compiled Flutter app, which already satisfies clause 4.2(c) of the GameDev Network terms the user quoted on purchase.

## Top-level layout

```
art-source/gnomes/
  LICENSE/License.txt
  PNG_sequences/              # 8 gnomes × ~180 frames each = 1440 frames (66 MB)
    blue_gnome/
    blue_hat_gnome/
    gnome/                    # base — 179 frames (one short vs others)
    green_gnome/
    no_hat_gnome/
    red_gnome/
    yellow_gnome/
    yellow_red_gnome/
  SCML_PNG_PARTS/             # Spriter rig + PNG parts (18 MB)
    gnome_base.scml
    gnomes.scml
    accessories/ boots/ clothes/ effects/ face/ hair/ hands/
  SVG_PARTS/                  # Vector puppet pieces (772 KB)
    accessories/ boots/ clothes/ effects/ face/ hair/ hands/
  gnome_all_parts.svg         # single-file master vector sheet
  info_about_scml_files.png   # vendor reference
  info_about_svg.png          # vendor reference
```

## Character variants

Eight palette swaps. Each has the same 26 animations and ~180 frames. Visual survey of [green_gnome idle](../art-source/gnomes/PNG_sequences/green_gnome/__green_gnome_idle_000.png) and [run](../art-source/gnomes/PNG_sequences/green_gnome/__green_gnome_run_000.png): a bearded gnome in boots with a **pointed hat**, facing **right**, carrying a **wooden staff in his lead hand**. Staff is baked into every frame; see "Design considerations" below.

- `gnome` — base palette (neutral / earthy)
- `green_gnome` — green hat + green shirt (closest to current Gurgles palette)
- `red_gnome`, `blue_gnome`, `yellow_gnome` — solid colour variants
- `blue_hat_gnome` — hat-only colour swap
- `yellow_red_gnome` — two-tone
- `no_hat_gnome` — bald, no hat (useful for rebuild / re-dressing via SVG parts)

Recommendation: ship **one** variant. `green_gnome` is the strongest match for Gurgles' existing web-game palette. 1 variant × curated frames ≈ ~3 MB added to APK (vs ~60 MB if we shipped all 8).

## Animations (frame counts from `green_gnome`)

| Animation | Frames | Relevant to V1? | Use |
|---|---|---|---|
| `run` | 8 | ✅ Core | Main locomotion — replaces the binary run-pose swap |
| `jump_start` | 7 | ✅ Core | Takeoff burst when jump input registered |
| `jump_cycle` | 12 | ✅ Core | Continuous airborne loop |
| `jump_in_air` | 1 | Maybe | Single airborne pose — simpler fallback than `jump_cycle` |
| `jump_land` | 6 | ✅ Core | Landing recovery |
| `hurt` | 6 | ✅ Core | Obstacle-hit game over (played once, then freeze on last frame) |
| `die` | 6 | ✅ Core | Spill-death game over (alternative stinger) |
| `dead` | 1 | ✅ Core | Final pose held on game-over overlay |
| `idle` | 20 | ⏳ Secondary | Menu-screen idle (post-V1 polish) |
| `falling` | 10 | ❌ | Extended fall — we don't fall off screen |
| `falling_to_land` | 5 | ❌ | Same — skip |
| `run_flip` | 10 | ❌ | Somersault (cosmetic — defer) |
| `run_jump` | 8 | ❌ | Dedicated run-to-jump transition — covered by `jump_start` |
| `dash_pose` | 1 | ❌ | No dash mechanic in V1 |
| `walk` | 8 | ❌ | We only run, never walk |
| `push` / `pull` | 8 / 8 | ❌ | No pushable objects |
| `ladder_climb` | 8 | ❌ | No ladders |
| `defend_intro` / `defending_pose` / `defend_outro` | 3 / 1 / 3 | ❌ | No defense mechanic |
| `throw_projectile` / `shoot` | 8 / — | ❌ | No projectiles |
| `staff_whack` / `staff_stab` | 8 / 7 | ❌ | No combat |
| `whacked` | 16 | ❌ | Melee hit reaction — we use `hurt` instead |
| `base` | 1 | ❌ | T-pose reference sheet |

**Minimum viable frame set for V1**: `run` (8) + `jump_start` (7) + `jump_cycle` (12) + `jump_land` (6) + `hurt` (6) + `dead` (1) = **40 frames**. Add `idle` (20) for menu polish = 60 frames.

## Frame format

- **Format**: PNG, RGBA, non-interlaced, transparent background.
- **Dimensions**: 647 × 559 px per frame (large — ~5× our current on-screen Gurgles size of ~100–130 px tall).
- **Alignment**: Frames share a consistent canvas. Frame-to-frame alignment appears baked — trusted for a spritesheet build via ImageMagick or Flutter's native frame animation.
- **Staff**: wooden staff with a small green tuft at the top is baked into hand positions in `idle`, `run`, and several other animations. See "Design considerations".

File size: ~45–55 KB per frame PNG. 40-frame minimum set ≈ 2 MB uncompressed; after PNG optimisation and ideally downsampling to ~256 px tall, **~500 KB – 1 MB added to APK**.

## SVG parts (customisation kit)

[SVG_PARTS/](../art-source/gnomes/SVG_PARTS/) contains the puppet pieces used to rebuild or re-dress the gnome. Useful if we ever want to **remove the staff** (by redrawing hand frames) or swap specific pieces.

- **accessories/** — belt buckles/straps, buttons, `hat.svg`, `staff.svg` (the staff as an isolated piece — handy to subtract)
- **boots/** — 4 boot angles (back/front/side/top) in black
- **clothes/** — shirt arms, legs, waist, waistcoat, shirt front/back (all base colours — palette variants are in `SCML_PNG_PARTS/clothes/`)
- **effects/** — `dust_puff.svg` (landing dust — could be wired to `Gurgles.onGround` later)
- **face/** — ear, head (back/side), eyes (open/closed, L/R), pupil, nose (×2 styles)
- **hair/** — 3 beards, 3 L moustaches, 3 R moustaches, eyebrows, head hair (front/back)
- **hands/** — 9 back-hand poses + 8 top-hand poses (useful for building custom hand positions)

These are only worth touching if we reject the baked-staff approach. For V1, ignore.

## SCML / Spriter rig

[SCML_PNG_PARTS/](../art-source/gnomes/SCML_PNG_PARTS/) contains the BrashMonkey Spriter rig (`gnome_base.scml`, `gnomes.scml`) + PNG versions of every puppet piece. **No maintained Flutter/Flame runtime exists for SCML**; the rig is useful only as:

- A reference if someone opens it in Spriter to export new keyframes or additional animations.
- A re-export source if we need a variant animation the pre-baked PNG sequences don't already cover.

For V1: ignore. The PNG sequences are all we need.

## Design considerations

### 1. The staff is a problem (or a feature)

Every animation that shows Gurgles' lead hand has him gripping a wooden staff. The original Mobile V1 design has Gurgles "running holding a giant tankard of hooch above his head." Three paths:

- **(A) Accept the staff as character detail.** Re-narrative: druid brewer gnome carries both a brewing staff and a magically-floating tankard. Tankard stays as a separate overlay above his head, as today. **Cheapest. No frame edits. Ship-ready.**
- **(B) Edit the staff out** of the ~40-frame V1 set. Open each frame in Aseprite / GIMP, mask out the staff region, feather in transparency. ~2–4 hours of careful pixel work. Hands end up awkwardly gripping air.
- **(C) Rebuild gnome from SVG parts without the staff**, export new PNG sequences from Spriter. Requires installing Spriter Pro, learning the rig, and re-exporting 40 frames. Largest effort, cleanest result.

**Recommendation: (A)**. The staff adds character; the "brewing druid with a staff and a tankard" framing is arguably tighter than "running with a tankard and nothing else."

### 2. Tankard overlay positioning

Current [gurgles.dart](../lib/components/gurgles.dart) renders the tankard as a separate SVG with `angle = tankardAngleForTilt(balance.tilt)` and a fixed position relative to the gurgles sprite. With a real run cycle the character's head position bobs per frame — the tankard overlay will either:

- Stay at fixed screen-Y (tankard floats independently of head — looks disconnected during run bob).
- Track per-frame head position (needs a per-animation-frame head-anchor lookup table).

For V1, fixed-Y is fine — the head bob on these frames is modest (~10 px). We can revisit if it looks bad on-device.

### 3. Sprite scale and hitbox implications

Current `Gurgles.size = Vector2(120, 120)` (see [game_config.dart](../lib/config/game_config.dart)). Source frames are 647 × 559 — mostly transparent padding. Before bundling:

1. Trim the bounding box of each frame to the actual pixel content (ImageMagick `-trim`).
2. Re-canvas-pad each frame back to a consistent size (so frame-to-frame alignment doesn't shift).
3. Downsample to target render size (e.g. 256 × 256 → Flame then scales to the 120-px sprite size cheaply).

Obstacle hitboxes are authored per-kind and won't change. Gurgles' current hitbox (defined in [gurgles.dart](../lib/components/gurgles.dart)) may need retuning once the actual content bounding box changes.

### 4. Menu vs game sprite

`green_gnome_idle` (20 frames) is a great menu-screen accent — Gurgles idling with his staff, breathing, while the player types their name. Cheap polish for later.

## What to ship in `assets/images/`

Proposed directory (after curation):

```
assets/images/gurgles/
  run/            __green_gnome_run_000.png … 007.png       (8 frames)
  jump_start/     __green_gnome_jump_start_000.png … 006.png (7 frames)
  jump_cycle/     __green_gnome_jump_cycle_000.png … 011.png (12 frames)
  jump_land/      __green_gnome_jump_land_000.png … 005.png  (6 frames)
  hurt/           __green_gnome_hurt_000.png … 005.png       (6 frames)
  dead/           __green_gnome_dead_000.png                 (1 frame)
  idle/           __green_gnome_idle_000.png … 019.png       (20 frames, optional)
```

All frames trimmed + downsampled via an `art-source/build-sprites.sh` script (ImageMagick) so the build is reproducible and the raw pack stays out of git. Alternative: pre-pack into a single Flame-native spritesheet PNG + JSON atlas per animation.

## Next step

See `docs/superpowers/plans/2026-04-21-gnome-animation-integration.md` (to be written) for the implementation plan.
