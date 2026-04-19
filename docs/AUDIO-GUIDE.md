# Hold the Hooch Mobile — Audio Guide

Audio spec for all SFX + (optional) music. Drop files into `assets/audio/` with the exact filenames below. The engine picks them up via `flame_audio` — no code changes needed for new clips at listed filenames.

## Style

Warm, small-scale, a little silly. The game's tone is "old Newgrounds flash game" + "a gnome is running through a forest trying not to spill his beer". Lean into whimsy. Think *Kirby* / *Stardew Valley* / early *Mario* — **not** cinematic, **not** hyperreal.

**Platform context:**
- Most players will be on a phone with the **speaker** or **on bluetooth**, often in the background while listening to a podcast (see [CLAUDE.md](../CLAUDE.md) — this is a "second-screen podcast game"). So:
  - SFX must be recognisable but **not shrill**.
  - Music (if we ship any) is **optional** — off by default, or a single ambient loop the player can toggle.
  - Every SFX should sit nicely **under voiceover**. No sharp mid-frequency spikes that clash with speech.
- Global master volume is set to 70% in code; design SFX at full volume and rely on that headroom.

## What's already in the repo

Nothing yet. This is a greenfield ask — no audio has been wired up.

---

## Sound effects

### `sfx-jump.wav` — Jump start

| Property | Value |
|----------|-------|
| **Filename** | `assets/audio/sfx-jump.wav` |
| **Format** | WAV, 44.1 kHz, 16-bit, mono |
| **Length** | ~150 ms |

**Design notes:**
- Light, cartoonish "boing" or cloth-swish with a short pitch-up tail.
- Triggered on the **down-edge** of a right-side tap (jump start).
- Because the player can jump 1–3× per second, it must be **short** and **non-fatiguing** — no deep subbass, no long reverb tail.

### `sfx-jump-big.wav` — Full-hold jump

| Property | Value |
|----------|-------|
| **Filename** | `assets/audio/sfx-jump-big.wav` |
| **Format** | WAV, 44.1 kHz, 16-bit, mono |
| **Length** | ~250 ms |

**Design notes:**
- Slightly grander version of `sfx-jump.wav`. Played when the player holds for the full jump (instead of tapping briefly).
- Pitch up farther, or layer a subtle "oof" exertion.
- Optional — if you only deliver one jump sound, we'll fall back to `sfx-jump.wav`.

### `sfx-land.wav` — Landing

| Property | Value |
|----------|-------|
| **Filename** | `assets/audio/sfx-land.wav` |
| **Format** | WAV, 44.1 kHz, 16-bit, mono |
| **Length** | ~100 ms |

**Design notes:**
- Soft thud on ground contact after a jump.
- Earthy / grassy — think "boot on moss".
- Very short — plays every time the player lands.

### `sfx-collect-herb.wav`, `sfx-collect-hop.wav`, `sfx-collect-potion.wav` — Collectible pickups

| Property | Value |
|----------|-------|
| **Filenames** | `assets/audio/sfx-collect-herb.wav`, `sfx-collect-hop.wav`, `sfx-collect-potion.wav` |
| **Format** | WAV, 44.1 kHz, 16-bit, mono |
| **Length** | ~300–500 ms each |

**Design notes:**
- Three-note pleasant chime sequence, ascending in pitch / reward:
  - **Herb** (10 pts, common): single soft chime, low–mid pitch, one note. Think bell-wind chime.
  - **Hop** (50 pts, uncommon): two-note ascending, brighter, slight shimmer.
  - **Potion** (200 pts, rare): three-note flourish, magical/mystical. A bit of sparkle / reverb. This is the "wow, nice!" moment.
- Must feel like **progression** across the three — players should hear an upgrade.

### `sfx-spill-warning.wav` — Spill meter threshold

| Property | Value |
|----------|-------|
| **Filename** | `assets/audio/sfx-spill-warning.wav` |
| **Format** | WAV, 44.1 kHz, 16-bit, mono |
| **Length** | ~300 ms |

**Design notes:**
- Fires **once** when `|tilt|` first crosses 0.7 (i.e. spill meter starts filling).
- A concerned liquid-slosh / wobble sound. Hints "ooh, that's not good".
- Don't loop — that was the V1 plan and it's too aggressive. Single warning is more podcast-friendly.

### `sfx-spill-game-over.wav` — Hooch spilled

| Property | Value |
|----------|-------|
| **Filename** | `assets/audio/sfx-spill-game-over.wav` |
| **Format** | WAV, 44.1 kHz, 16-bit, mono |
| **Length** | ~800 ms |

**Design notes:**
- Big satisfying splash + a tragic little "noooo" sigh or sad trombone touch.
- Plays at the moment the spill meter hits 100% and the game transitions to Game Over.
- This is one of two game-over sounds (the other is collision).

### `sfx-collision.wav` — Obstacle hit

| Property | Value |
|----------|-------|
| **Filename** | `assets/audio/sfx-collision.wav` |
| **Format** | WAV, 44.1 kHz, 16-bit, mono |
| **Length** | ~500 ms |

**Design notes:**
- Dull thud + a small "oof". Not a cartoonish BONK — subtler.
- Plays when Gurgles runs into an obstacle.

### `sfx-ui-tap.wav` — Menu button tap

| Property | Value |
|----------|-------|
| **Filename** | `assets/audio/sfx-ui-tap.wav` |
| **Format** | WAV, 44.1 kHz, 16-bit, mono |
| **Length** | ~80 ms |

**Design notes:**
- Soft wooden knock / tap confirmation.
- Plays on Start, Retry, Menu buttons.

### `sfx-new-best.wav` — New personal best

| Property | Value |
|----------|-------|
| **Filename** | `assets/audio/sfx-new-best.wav` |
| **Format** | WAV, 44.1 kHz, 16-bit, mono |
| **Length** | ~1.2 s |

**Design notes:**
- Triumphant little jingle. Played on the GameOver overlay if this run beat the player's saved best.
- Slightly more elaborate than a collectible chime — 4–6 notes, warm.

---

## Music (optional for V1)

If we ship music in V1 at all, we want **one** ambient loop. Off by default, toggle in a future settings menu.

### `bgm-forest-night.ogg` — Ambient run loop

| Property | Value |
|----------|-------|
| **Filename** | `assets/audio/bgm-forest-night.ogg` |
| **Format** | OGG Vorbis, 44.1 kHz, stereo, ~128 kbps |
| **Length** | 60–120 seconds, seamlessly looping |

**Design notes:**
- A dusk-forest ambience. Low, warm, atmospheric.
- Suggested instrumentation: soft guitar or harp, light pad, distant flute, occasional forest wildlife (cricket, owl hoot) — but restrained.
- **No percussion.** Or if any, very soft mallets / wood taps. Tempo around 80–90 BPM so the gameplay can rhythmically sit on top without conflict.
- **Absolutely no vocals** — this must sit under the player's own podcast.
- First and last 2 seconds of the file should crossfade to loop seamlessly.
- Master headroom: peak at -3 dB to leave room for SFX over the top.

---

## Technical / format rules

- **SFX format:** WAV, 44.1 kHz, 16-bit, mono. (Exception: crash / game-over SFX can be stereo if needed for width.)
- **Music format:** OGG Vorbis, 44.1 kHz, stereo, ~128 kbps.
- **Mastering:** peak at -3 dB, no clipping. Normalise relative to `sfx-jump.wav` as the loudness reference for in-game events.
- **Silence trim:** remove all leading/trailing silence — the engine handles scheduling.
- **Filenames:** lowercase, hyphen-separated. No spaces, no unicode.
- **File paths:** drop everything into `assets/audio/`.

## Delivery

- Drop audio files into `assets/audio/` with the exact filename listed.
- If a filename isn't listed but you think it's needed, name it consistently (`sfx-*.wav` / `bgm-*.ogg`) and mention it when you hand over.
- No PR required — I'll wire each clip into the component that fires it (jump, land, collect, spill, etc.) as they come in.

## Priority if you only have time for a few

1. `sfx-jump.wav` — fires constantly, biggest game-feel win
2. `sfx-collision.wav` + `sfx-spill-game-over.wav` — every run ends with one of these
3. `sfx-collect-herb/hop/potion.wav` — makes the risk/reward loop feel rewarding
4. `sfx-new-best.wav` — retention hook
5. `sfx-ui-tap.wav`, `sfx-land.wav`, `sfx-spill-warning.wav` — polish
6. `bgm-forest-night.ogg` — optional, defer to post-V1
