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

CodeMagic UI → Teams → Integrations → App Store Connect → **Add**. Name it **`GZBO`** (matches what `codemagic.yaml:195` references — was renamed 2026-04-20 to match the team-level integration). Paste the Issuer ID, Key ID, and .p8 file contents.

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

### 6. First-build signing (manual cert + profile uploads — do this BEFORE step 5)

**CodeMagic's "automatic iOS code signing" does NOT work for first-time Apple Developer accounts** (confirmed 2026-04-21 — private-key generation silently fails, build loop burns hours). Skip the auto flow. Do this one-time manual setup instead:

**Step A — Generate private key + CSR on Windows (OpenSSL, no Mac needed).**

```bash
# In a directory that's gitignored (we use ios-signing/ in the repo):
openssl genrsa -out ios_distribution.key 2048
MSYS_NO_PATHCONV=1 openssl req -new -key ios_distribution.key -out ios_distribution.csr \
  -subj "/emailAddress=callum.siciliano@gmail.com/CN=Callum Siciliano/C=GB"
```

The `MSYS_NO_PATHCONV=1` prefix stops Git Bash from mangling the `/subj=` string into a path.

**Step B — Get the cert from Apple.** Apple Developer portal → Certificates → **+** → Apple Distribution → upload `ios_distribution.csr` → download the resulting `ios_distribution.cer`.

**Step C — Bundle cert + key into .p12 with a random password.**

```bash
openssl x509 -inform DER -in ios_distribution.cer -out ios_distribution.pem
P12_PASS=$(openssl rand -base64 16 | tr -d '/+=')
echo "$P12_PASS" > p12_password.txt   # save for the next step
openssl pkcs12 -export -legacy \
  -inkey ios_distribution.key \
  -in ios_distribution.pem \
  -out ios_distribution.p12 \
  -passout pass:$P12_PASS
```

The `-legacy` flag is needed with OpenSSL 3+ for CodeMagic compatibility.

**Step D — Upload .p12 to CodeMagic.** CodeMagic UI → Teams → **Code signing identities** → iOS certificates → **Add certificate**. Upload `ios_distribution.p12`, paste the password from `p12_password.txt`.

**Step E — Create App Store provisioning profile at Apple.** Apple Developer portal → Profiles → **+** → Distribution → **App Store** → select bundle id → select the Apple Distribution cert from Step B → name it `HoldTheHooch App Store` → Generate. Download the `.mobileprovision`.

**Step F — Upload .mobileprovision to CodeMagic.** CodeMagic UI → Teams → **Code signing identities** → iOS provisioning profiles → Upload the `.mobileprovision` from Step E.

Now step 5 (tag + push) works — the canonical `ios_signing` block in `codemagic.yaml` finds both cert and profile in CodeMagic's team store and signs the IPA.

### 7. Other first-build gotchas

- Flutter iOS projects need `ios/Runner.xcodeproj` bundle identifier to match **exactly** what's in Apple Developer + App Store Connect. Our project pbxproj has `beer.gurgles.holdTheHooch` — double-check if Apple rejects.
- If `fetch-signing-files --create` orphans a cert on Apple (creates it but can't save the private key), you'll see it in Apple Developer → Certificates with no local private key to pair it with. Revoke it before retrying or it'll get reused.

---

## Cost notes

- `linux_x2` instance (Android): Free tier includes 500 min/month.
- `mac_mini_m2` instance (iOS): Free tier includes 500 min/month on M2.
- Current config triggers iOS debug build on every push to main. If that gets expensive, change `ios-debug` trigger to a separate branch (e.g. `ios-ci`) or manual-only.

## Rotating keys / secrets

- **CodeMagic API token:** if a token has been shared (chat transcript, etc.), rotate it: CodeMagic UI → Teams → Personal Access Tokens → revoke + regenerate.
- **App Store Connect .p8:** rotate via App Store Connect if exposed.
- **Google Play service account:** rotate via Google Cloud Console.
