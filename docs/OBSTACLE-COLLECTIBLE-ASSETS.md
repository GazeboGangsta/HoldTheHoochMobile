# Obstacle + Collectible Asset Staging — Inventory

Staging survey of art packs in `temp/` (gitignored working dir) for the upcoming M5a obstacle + collectible refresh. Goal: replace the web-game SVGs for `root / rock / mushroom / log` obstacles and `herb / hops / potion` collectibles with pixel-art that matches the Pine Hills parallax + gnome-pack character.

## User-stated design intent (2026-04-21)

- **Fruits + vegetables** → new **collectibles** across tiers (value / rarity).
- **Boulders, rocks, mushrooms** → **obstacles**. Roster may expand beyond the current 4 kinds.
- **Potions** → **collectibles AND potentially power-ups**. New gameplay axis; V1 can swap art only, power-ups land separately.

## Pack licences — all commercial-OK

| Pack | Source | Licence verdict |
|---|---|---|
| Individual fruits/veg PNGs (17 files) | itch.io (user confirmed) | ✅ Commercial OK |
| Individual rock/stone PNGs (4 files) | itch.io (user confirmed) | ✅ Commercial OK |
| `Log_sprite.png` | itch.io (user confirmed) | ✅ Commercial OK |
| `Mushrooms.zip` — 3 animated mushrooms | itch.io (user confirmed) | ✅ Commercial OK |
| `nature full.zip` — 100 Nature Things by Shubibubi | itch.io | ✅ Commercial OK. *"This asset pack can be used in any commercial or non commercial project, you may modify the assets as you wish. This asset pack can't be resold/redistributed even if modified."* |
| `Potions by Onocentaur.zip` — 160 potions | onocentaur.itch.io | ✅ Commercial OK. *"Free to use for personal & professional projects. Attribution appreciated."* |
| `VariPixels PotionsPack 02112022 Update` | itch.io (user confirmed purchase) | ✅ Commercial OK (no `LICENSE.txt` bundled; user asserts commercial rights) |

### Discarded (don't ship)

- `nature free.zip` / `nature_free/` — older **free-version** of the same Nature pack, **non-commercial only**. Superseded by `nature full.zip`. Delete the free folder when curating.

## Pack details

### 1. Fruits & vegetables (17 individual PNGs, 32×32)

Clean pixel art, strong silhouettes, consistent style across the set. Colour palette reads well against the Pine Hills dusk backdrop.

| File | What it is | Colour | Proposed tier |
|---|---|---|---|
| `Strawberry.png` | Strawberry with leafy top | Red | Tier 1 — common |
| `Cherry.png` | Two cherries on stem | Red | Tier 1 — common |
| `Tomato.png` | Tomato with green calyx | Red | Tier 1 — common |
| `Apple.png` | Classic red apple | Red | Tier 2 — medium |
| `Apple (2).png` | Darker / bruised red apple | Dark red | Tier 2 — medium (variant) |
| `GreenApple.png` | Green apple | Green | Tier 2 — medium |
| `Orange.png` | Orange citrus | Orange | Tier 2 — medium |
| `Pumpkin.png` | Ridged pumpkin | Orange | Tier 2 — medium |
| `Carrot.png` | Carrot with green top | Orange | Tier 2 — medium |
| `Banana(yellow).png` | Ripe yellow banana | Yellow | Tier 2 — medium |
| `Banana (Green).png` | Unripe green banana | Green | Tier 1 — low (unripe) |
| `Avocado.png` | Dark green avocado | Dark green | Tier 2 — medium |
| `Garlic.png` | White garlic bulb | White | Tier 1 — novelty |
| `Onion.png` | Purple shallot/garlic drop | Purple | Tier 1 — novelty |
| `Onion (2).png` | Orange-brown onion bulb | Orange-brown | Tier 1 — novelty |
| `GoldenApple.png` | 🌟 **Gold apple with shine** | Gold | **Tier 3 — rare jackpot** |

### 2. Rocks + boulders + log (5 individual PNGs)

| File | Dimensions | Style |
|---|---|---|
| `Boulder 32x32.png` | 32×32 | Smooth grey rounded boulder |
| `MossyBoulder 32x32.png` | 32×32 | Same silhouette + moss overlay |
| `Rock_03 32x32.png` | 32×32 | Darker, more angular rock |
| `Stone_01 16x16.png` | 16×16 | Small black stone / pebble |
| `Log_sprite.png` | 256×64 = 4 frames of 64×64 | Log with leaf — 4-frame sway animation |

### 3. Animated mushrooms (`Mushrooms.zip`)

| File | Dimensions | Content |
|---|---|---|
| `AnimatedMushroomRed.png` | 384×384 | 8-frame gentle bob, 3×3 grid (8 used + 1 empty) |
| `AnimatedMushroomPink.png` | 384×384 | Same animation, pink cap variant |
| `AnimatedMushroomBlue.png` | 384×384 | Same animation, blue cap variant |

Red = classic toadstool, Pink = rare variant, Blue = mythical variant.

### 4. Nature Full — 100 Nature Things by Shubibubi (`nature full.zip`)

The big one. `global.png` is a **160×208 grid at 16×16 per cell** = 10 columns × 13 rows, with the content packed as 10 categories × 10 items each (100 total + extras). `global_shadow.png` is the same atlas with grounded drop shadows (useful for obstacle-style objects that should look planted on the ground).

| Row (approx) | Category | 10 items |
|---|---|---|
| 1-2 | Trees | Apple, Orange, Birch, Pine, Plum, Pear, Dragon, Cherry Blossom, Cursed, Dead Old Oaktree |
| 3 | Leaves | Apple, Orange, Birch, Pine, Plum, Pear, Dragon, Autumn×3 |
| 4 | Nuts | Hazelnut, Walnut, Almond, Cashew, Macadamia, Peanut, Pecan, Brazil, Pistachio, Pine Nut |
| 5-6 | Bushes | Raspberry Bush, Winter Creeper, Hydrangea, Persian Shield, Juniper Blue Star, Dwarf Norway Spruce, Daphne Odora, Dog Wood, Camelia, Azalea |
| 7 | Flowers | Hedgenettle, Dandelion, Knapweed, Poppy, Chamomile, Foxglove, Musk Mallow, Tansy, Crying Heart, Crested Dog Tail |
| 8 | Mushrooms | White Button, Crimini, Shitake, King Oyster, Enoki, Beech, Black Trumpet, Chanterelle, Morel, Death Cap |
| 9 | Rocks | Chalk, Mudstone, Gold, Silver, Copper, Diabase, Soapstone, Obsidian, Pumice, Scoria |
| 10 | Crystals | Rose Quartz, Jasper, Citrine, Turquoise, Tiger Eye, Amethyst, Moonstone, Sapphire, Quartz, Bloodstone |
| 11-12 | Bugs | Ladybug, Bee, Orbweaver Spider, Roly Poly, Grasshopper, Luna Moth, Death's-Head Hawk Moth, Dragonfly, Cockroach, Earthworm |
| 13 | Butterflies | Monarch, Peacock, Zebra Swallowhead, Red Admiral, Morpho, Julia, Parides Montezuma, Orange Daggerwing, Carolina Satyr, Mourning Cloak |

This pack **significantly expands design possibilities**:
- **Crystals (10)** — obvious high-tier collectibles (gemstone loot)
- **Nuts (10)** — small, chunky collectibles — would tile nicely in Tier 1
- **Leaves (10)** — could be *collectibles* OR *falling-leaf particles* for ambient mood
- **Flowers (10)** — ground-level scenery OR alt collectibles
- **Butterflies (10)** — if we animate them, they become *moving collectibles* (catch one as it flies past). Big gameplay-variety bump.
- **Bugs (10)** — animated *moving obstacles* (ladybug crawling, spider dropping from web)
- **Rocks (10)** — richer obstacle variety than the 4 individual rock PNGs
- **Mushrooms (10)** — static alternatives to the 3 animated ones
- **Bushes (10)** — foreground parallax decoration (independent of obstacles)
- **Trees (10)** — ditto, though Pine Hills already handles bg trees

Because this is a single-atlas layout at 16×16 per cell, we'd slice it at build-time (extend `tools/build_gurgles_sprites.dart`-style pipeline to extract per-category sub-sprites).

### 5. Onocentaur Potions — 160 bottles (`Potions by Onocentaur.zip`)

`Potions - Full, Corked.png` — 160×400 atlas. Tile size 16×24 (declared in image footer). **10 bottle designs × 16 colour variants = 160 full, corked potions.**

Style: modest heart/teardrop silhouettes, bright solid colour palette, slight highlights. Clean pixel art. Attribution appreciated but not required.

Additional companion packs available from Onocentaur (not downloaded, see https://onocentaur.itch.io/potions): half-filled and empty bottles, alternate corks, effects. 15,000+ unique combinations if we go deep.

**Use:** direct 1:1 replacement for the current `potion` collectible, with room for V2 power-up variants (each bottle design could be a different power-up kind — e.g. a red heart-flask = speed boost, blue tall-bottle = invulnerability, etc.).

### 6. VariPixels Potions (`VariPixels PotionsPack 02112022 Update/`)

Four sheets at 32×32 tile size:

| File | Dimensions | Contents |
|---|---|---|
| `PotionsPack1.png` | 352×704 | 11 cols × 22 rows = 242 containers. Full flasks, pouches, cups, vials, chests, bottles, jars, tall jars, stars, spiked bottles, ornate bottles. Each in 10 colour variants + 1 outline. |
| `PotionsPack2.png` | 352×704 | Same grid. Likely half-filled / different states. |
| `PotionsPack3.png` | 352×704 | Same grid. Likely empty / different states. |
| `PotEffects.png` | 352×32 | 11 effect sparkles at 32×32 — for use as particle overlays on pickup. |

**Total: ~726 potion container sprites + 11 effects.** Huge library, significantly richer than Onocentaur's but less thematically focused.

**Design note:** this pack is a *"pick what you need"* library rather than a ready-to-ship set. If we use it, we'd curate ~5-10 specific variants into `assets/images/collectibles/potions/` and ignore the rest.

## Recommended V1 curated set

Following the gnome / Pine Hills pattern — curate a small, opinionated subset now, leave room for V2 expansion.

### Collectibles (3 tiers + rare + potion)

```
assets/images/collectibles/
  strawberry.png         # Tier 1, ~10 pts
  cherry.png             # Tier 1, ~10 pts
  tomato.png             # Tier 1, ~10 pts
  apple.png              # Tier 2, ~25 pts
  orange.png             # Tier 2, ~25 pts
  pumpkin.png            # Tier 2, ~25 pts
  golden_apple.png       # Tier 3, ~75 pts + 1s spill-drain bonus (inherits current potion behaviour)
  potion_red.png         # Special — one curated variant from Onocentaur or VariPixels
                         #   (decide on pack first; see "Decision" below)
```

That's 8 files for V1 — matches the current 3-kind structure (`herb / hops / potion`) but richer. Banana, Avocado, Carrot, Garlic, Onions held in reserve for V2.

### Obstacles (4 kinds, matching current enum)

```
assets/images/obstacles/
  rock.png               # Rock_03 (sharp angular rock — replaces current `rock`)
  boulder.png            # Boulder (rounded — optional second `rock` variant for RNG)
  mossy_boulder.png      # MossyBoulder (green-moss variant)
  log.png                # Log_sprite frames 0-3 (4-frame sway anim) — replaces current `log`
  mushroom_red.png       # AnimatedMushroomRed (8-frame) — replaces current `mushroom`
  mushroom_pink.png      # Variant
  mushroom_blue.png      # Variant (rare RNG roll)
```

**Open question: what replaces `root`?** Three options:
1. **Drop `root`** — ship 3 kinds (rock / mushroom / log). Simplest.
2. **Keep `root` SVG** from the web game alongside pixel-art. Style mismatch.
3. **Repurpose a Nature Full item** — e.g. a bush silhouette as a "thicket" obstacle, or a static dead-oaktree base. Would introduce Nature Full into the obstacle pipeline.

My recommendation: **(1) drop root for V1**, ship 3 obstacle kinds. Add new kinds from Nature Full in V2.

### Decision needed: Onocentaur vs VariPixels for potion art?

- **Onocentaur** — 160 potions, one-atlas, heart/teardrop silhouettes, clean thematic. Bottle designs read clearly at small pickup size. Smaller file commitment.
- **VariPixels** — 726 containers, very richly detailed, but more variation in style (flasks / pouches / chests / stars — not all feel "potion"). Better if we go heavy on power-up variants.

**My recommendation: Onocentaur for V1** — cleaner thematic consistency, simpler curation. VariPixels is the fallback if we ever need a power-up variant that Onocentaur doesn't cover.

## V2 expansion ideas (not for V1)

- **Crystal collectibles** (Nature Full Row 10) — new `CollectibleKind.crystal` with 10 colour variants. Bigger score bump than fruits.
- **Butterfly collectibles** (Nature Full Row 13) — *moving* collectibles that fly past at a slower-than-world speed. Catch them by jumping at the right moment. New gameplay axis.
- **Bug obstacles** (Nature Full Rows 11-12) — small animated obstacles (crawling / dropping) that complement static rocks/logs.
- **Power-up potions** — different bottle designs trigger different effects: speed boost, temporary invulnerability, score multiplier, double-jump unlock. Requires design work + UI to surface active power-up timers.
- **Falling-leaf ambient particles** (Nature Full Row 3) — not gameplay, just mood. Slow-drift leaves across the screen, independent of scroll speed (similar to cloud drift).
- **Nut collectibles** (Nature Full Row 4) — small, chunky, could be Tier 1 "common" replacement or a collect-10-for-bonus mechanic.
- **Flower bushes as scenery** (Nature Full Rows 5-7) — another ground-level parallax layer.

## Pipeline recommendations

Following the established pattern from gnomes / Pine Hills:

1. **Stage raw packs** at `assets/third_party/<pack_name>/` with LICENSE files bundled. Keep them ungitignored so they ship in the bundle for future use / regeneration.
2. **Individual sprite files per kind** at `assets/images/collectibles/` and `assets/images/obstacles/`. Descriptive filenames, PNG per file. Flame `Sprite.load` per-file — same pattern as Gurgles' animation frames.
3. **Atlas slicing tool** for Nature Full (and the animated mushrooms, Log_sprite, PotionsPack atlases): extend the existing `tools/build_gurgles_sprites.dart` pattern OR write a companion `tools/build_obstacle_collectible_sprites.dart`. Takes the source atlas + a list of `{name, col, row, w, h}` slice specs, outputs named PNG per tile to the curated asset dirs.
4. **`pubspec.yaml`** — register `assets/images/obstacles/` + `assets/images/collectibles/` subfolders explicitly (non-recursive asset resolver — see Pine Hills gotcha).
5. **Animated-sprite support**: `Obstacle` and `Collectible` components currently load one `Sprite`. Extend them to accept a `SpriteAnimation` for animated kinds (mushroom bob, log sway). Follow the `Gurgles` → `SpriteAnimationComponent` pattern from `feat/gnome-animations`.
6. **Enum extensions**: `ObstacleKind` + `CollectibleKind` in `lib/components/obstacle.dart` + `collectible.dart` gain new values. Each kind maps to its sprite/animation path, hitbox inset, score value (collectibles only), and spawn weight (RNG selection frequency).

## Next step

Write the M5a obstacle+collectible refresh implementation plan using this inventory as the sourcing spec. Plan should include:
- Atlas slicing tool (for Nature Full + mushroom sheets + log strip + potion atlas)
- `Obstacle` / `Collectible` component extension to support animated sprites
- Enum additions + per-kind config tables
- Curation + commit of the shortlist assets
- Device playtest + tune
- Docs sweep

## Appendix — file size budget check

If we ship the recommended V1 set (8 collectibles + 7 obstacles = 15 individual sprites, mostly 32×32 PNGs + some small animation strips):

- ~15 curated sprites × ~1-5 KB each = ~50 KB
- 4-frame log strip at 256×64 = ~1 KB
- 8-frame mushroom sheet at 384×384 × 3 variants = ~60 KB

**Total ~110 KB** added to the APK/IPA. Negligible against the current ~21 MB IPA.

Leftover raw packs staged at `assets/third_party/` add ~400 KB more — still negligible — and are worth keeping tracked so re-curation never requires re-downloading packs.
