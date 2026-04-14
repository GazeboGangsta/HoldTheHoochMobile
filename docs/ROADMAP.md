# Roadmap

_See [STATUS.md](STATUS.md) for the live end-of-session snapshot._

## V1 — Ship to both stores

### M1 — Project scaffold ✅ Complete
- [x] Directory layout, CLAUDE.md, planning docs
- [x] `flutter create` the app, wire up Flame
- [x] SVG pipeline via `flame_svg`
- [x] CI: GitHub Actions for lint + test + Android debug build

### M2 — Core run loop ✅ Complete
- [x] Menu scene with name entry (Flutter widget)
- [x] Game scene with scrolling ground + Gurgles running
- [x] Tap-to-jump with variable height
- [x] Obstacle spawner with all 4 kinds + collision → GameOver
- [x] Score HUD + Game Over overlay + Retry/Menu flow

### M3 — Hooch balance mechanic ✅ Complete
- [x] HoochBalance component with tilt + passive wobble
- [x] Drag input on left half → counter-torque
- [x] Spill meter UI + game-over-on-100%
- [x] Jump impulse feeds into tilt

### M4 — Content pass ⏳ Partial
- [x] All 4 obstacle types (root / rock / mushroom / log)
- [ ] Collectibles (herb 10pts / hop 50pts / potion 200pts)
- [x] Difficulty curve wired up (speed 1.0x → 2.0x over 180s)
- [x] Scoring (+10/sec baseline)
- [ ] Score multiplier (+0.1x per 10s, capped 3x)
- [x] GameOver scene with submit

### M5 — Polish & assets ⏳ Partial
- [x] Real SVGs from web game (Gurgles, hooch, obstacles, parallax)
- [x] Parallax background (mountains + trees)
- [ ] Replace binary run/jump sprite swap with animated run cycle
- [ ] Particle / wobble juice on hooch (visible rotation)
- [ ] Obstacle hitbox tuning pass (currently too generous)
- [ ] SFX (jump / land / collect / spill / gameOver)
- [ ] Leaderboard scene (`GET /api/scores/top`)

### M6 — Store prep ❌ Not started
- [ ] App icon + splash
- [ ] Privacy policy (reuse gurgles.beer one)
- [ ] Screenshots, store listings
- [ ] Android: signed AAB, Play Console internal testing
- [ ] iOS: TestFlight build, App Store Connect listing — blocked on first successful iOS build on the MacBook; Xcode Cloud setup is the plan
- [ ] Submit to both stores

## Post-V1 ideas (not scheduled)

- Haptics on jump / spill
- Accelerometer tilt control as an alternate input
- Background music
- Daily seed / daily challenge leaderboard
- Character skin unlocks tied to score thresholds
- Landscape mode
- iPad / tablet layout pass
- Optional 2.5D / parallax-heavy visual upgrade
