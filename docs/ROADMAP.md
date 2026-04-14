# Roadmap

## V1 — Ship to both stores

Milestones, in order:

### M1 — Project scaffold
- [x] Directory layout, CLAUDE.md, planning docs
- [ ] `flutter create` the app, wire up Flame
- [ ] Add placeholder SVG pipeline (flutter_svg or Flame SVG support)
- [ ] CI: GitHub Actions for lint + test

### M2 — Core run loop (grey-box)
- [ ] Boot + Menu scenes with name entry
- [ ] Game scene with scrolling ground + Gurgles running (rectangles are fine)
- [ ] Tap-to-jump with variable height
- [ ] Obstacle spawner with 1 obstacle type + collision → GameOver

### M3 — Hooch balance mechanic
- [ ] HoochBalance component with tilt state + passive wobble
- [ ] Drag input on left half → counter-torque
- [ ] Spill meter UI + game-over-on-100%
- [ ] Jump impulse feeds into tilt

### M4 — Content pass
- [ ] All 4 obstacle types
- [ ] All 3 collectibles
- [ ] Difficulty curve wired up
- [ ] Scoring + multiplier
- [ ] GameOver scene with submit

### M5 — Polish & assets
- [ ] Replace greyboxes with first-pass SVGs (per `docs/ASSETS.md`)
- [ ] Parallax background
- [ ] Particle / wobble juice on hooch
- [ ] SFX
- [ ] Leaderboard scene

### M6 — Store prep
- [ ] App icon + splash
- [ ] Privacy policy (reuse gurgles.beer one)
- [ ] Screenshots, store listings
- [ ] Android: signed AAB, Play Console internal testing
- [ ] iOS: TestFlight build, App Store Connect listing
- [ ] Submit

## Post-V1 ideas (not scheduled)

- Haptics on jump / spill
- Accelerometer tilt control option
- Background music
- Daily seed / daily challenge leaderboard
- Character skin unlocks tied to score thresholds
- Landscape mode
- iPad / tablet layout pass
- Optional 2.5D / parallax-heavy visual upgrade
