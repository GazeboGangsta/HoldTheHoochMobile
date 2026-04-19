# Signing & release setup

How to finish CodeMagic configuration for production Android + iOS releases. Debug workflows (`android-debug`, `ios-debug`) don't require any of this — they run on push to `main` out of the box.

## Android — release AAB + Play Store

### 1. Generate a signing keystore (one-time)

On any machine with `keytool`:

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Remember the passwords. **Back up the keystore somewhere safe** — losing it means losing the ability to update the app on Play Store.

### 2. Upload to CodeMagic

CodeMagic UI → Teams → Environment variables → create group **`android_signing`** with:

| Variable | Value | Notes |
|----------|-------|-------|
| `CM_KEYSTORE` | `<base64 of .jks>` | `base64 upload-keystore.jks \| pbcopy` (macOS) or `base64 -w 0 upload-keystore.jks` (Linux) |
| `CM_KEYSTORE_PASSWORD` | `<password>` | Mark as Secret. |
| `CM_KEY_ALIAS` | `upload` | |
| `CM_KEY_PASSWORD` | `<key password>` | Mark as Secret. |

### 3. Optional: Play Console integration

Only needed if we want CodeMagic to auto-upload to the Play Store internal testing track.

1. Create a service account in Google Cloud Console, grant it Play Console permissions.
2. Download the JSON key.
3. Add `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` (paste the JSON) to the same `android_signing` group.
4. Uncomment the `google_play:` publisher block in `codemagic.yaml`.

Without this, the release workflow still produces a signed AAB as a downloadable artifact — just upload manually to Play Console the first time.

### 4. Trigger a release

```bash
git tag v1.0.0
git push origin v1.0.0
```

CodeMagic picks up the tag, runs `android-release`, publishes AAB.

---

## iOS — TestFlight

### 1. App Store Connect API key (one-time)

1. App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API** → generate a key with role **App Manager**.
2. Download the `.p8` key file. Note the `Key ID` and `Issuer ID`.
3. **Back up the .p8 file** — Apple only lets you download it once.

### 2. Register the integration in CodeMagic

CodeMagic UI → Teams → Integrations → App Store Connect → **Add**. Name it **`App Store Connect API Key`** (matches what `codemagic.yaml` references). Paste the Issuer ID, Key ID, and .p8 file contents.

### 3. Ensure bundle id is registered

Apple Developer portal → Identifiers → **+** → App IDs → App. Use:

- Description: Hold the Hooch
- Bundle ID: `beer.gurgles.holdTheHooch` (explicit, not wildcard)

### 4. Create the app in App Store Connect

App Store Connect → My Apps → **+** → New App.

- Platforms: iOS
- Name: Hold the Hooch
- Primary language: English (UK)
- Bundle ID: `beer.gurgles.holdTheHooch` (picked from dropdown — must match step 3)
- SKU: `hold-the-hooch-ios-v1` (internal identifier, your choice)

### 5. Trigger a release

```bash
git tag v1.0.0
git push origin v1.0.0
```

CodeMagic picks up the tag, runs `ios-release`, uploads the IPA to TestFlight. First upload takes 10–30 minutes for Apple to process before it's visible in TestFlight.

### 6. First-build gotchas

- Flutter iOS projects typically need `ios/Runner.xcodeproj` bundle identifier to match **exactly** what's in Apple Developer + App Store Connect. Our project pbxproj has `beer.gurgles.holdTheHooch` — double-check if iTunes rejects.
- If `flutter build ipa` fails on missing provisioning profile, CodeMagic's managed-signing should auto-generate one. If it doesn't, switch `distribution_type` to `development` for the first run, confirm build works, then switch back.

---

## Cost notes

- `linux_x2` instance (Android): Free tier includes 500 min/month.
- `mac_mini_m2` instance (iOS): Free tier includes 500 min/month on M2.
- Current config triggers iOS debug build on every push to main. If that gets expensive, change `ios-debug` trigger to a separate branch (e.g. `ios-ci`) or manual-only.

## Rotating keys / secrets

- **CodeMagic API token:** if a token has been shared (chat transcript, etc.), rotate it: CodeMagic UI → Teams → Personal Access Tokens → revoke + regenerate.
- **App Store Connect .p8:** rotate via App Store Connect if exposed.
- **Google Play service account:** rotate via Google Cloud Console.
