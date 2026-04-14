# Platform Notes — iOS build from a Windows dev machine

Flutter + Flame development happens on Windows (Android Studio + Android SDK). iOS builds require macOS + Xcode, which lives on your MacBook. A few practical options, ranked by effort:

## Option 1: Xcode Cloud (recommended once we're ready to ship)

- Available with your paid Apple Developer Program membership.
- Hooks into this GitHub repo. Each push to `main` (or tag) triggers a build, archives an IPA, and can auto-submit to TestFlight.
- Requires one-time setup on the Mac: open the `ios/` folder in Xcode, sign in with the Apple ID, configure signing, connect the repo in App Store Connect → Xcode Cloud.
- **Best fit for us** — we don't have to do local iOS builds until we want to debug something iOS-specific.

## Option 2: GitHub Actions with a macOS runner

- `macos-latest` runners can run `flutter build ipa`.
- Free minutes are limited and macOS minutes are billed at 10x the Linux rate, so keep it gated to release tags.
- Useful as a backstop if Xcode Cloud becomes unavailable.

## Option 3: Manual build on the MacBook

- `git pull` on the Mac, `flutter pub get`, open `ios/Runner.xcworkspace` in Xcode, archive + upload.
- Fine for one-off debugging, painful as a regular workflow.

## Recommendation

1. Keep building for Android on the Windows machine throughout V1 dev.
2. Once the game is fun and we're ~M5, do one manual iOS build on the Mac to catch any iOS-specific issues (permissions plist, signing, portrait-only orientation locks).
3. Set up Xcode Cloud before M6 store prep so TestFlight builds happen automatically on push.

## iOS-specific things to watch for later

- `ios/Runner/Info.plist` — add usage descriptions for any sensors we end up using (none required for V1 controls).
- `CFBundleDisplayName` = "Hold the Hooch".
- Portrait-only orientation already set in `main.dart` via `SystemChrome.setPreferredOrientations`.
- Flame + `flame_svg` is iOS-compatible — no native plugin work expected.
