# Setup

## Flutter SDK

Pinned to **3.24.5** (Dart ^3.5.4) because the primary dev machine runs macOS 12.7.6 — Flutter/Dart
releases newer than this require macOS 14+ to even run (`VM initialization failed: Current Mac OS X
version 12.0 is lower than minimum supported version 14.0`). Installed manually (not via Homebrew, which
only ships latest) to `~/development/flutter`, added to `PATH` in `~/.zshrc`. If developing on a newer
macOS, you can `flutter upgrade` freely — just re-check `pubspec.yaml` dependency ceilings first (some
packages there are pinned below their latest for SDK compatibility; see comments in `pubspec.yaml`).

## Supabase project

1. Create a project at [supabase.com](https://supabase.com) (or run one locally with the Supabase CLI —
   `supabase init && supabase start` — if you want a fully offline dev loop).
2. Open the SQL editor and run [`supabase/migrations/0001_init.sql`](../supabase/migrations/0001_init.sql)
   in full.
3. From Project Settings → API, copy the **Project URL** and **anon public key**.
4. Copy `.env.example` to `.env` in the repo root and fill in both values:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```
   `.env` is gitignored — never commit real credentials.

## Running the app

```
flutter pub get
flutter run
```

Without a valid `.env`, the app boots to a "Missing configuration" screen instead of crashing — useful for
verifying UI changes before Supabase credentials are wired up.

`flutter run` needs a **target device** already running/connected — see below for the Android emulator,
or run `flutter devices` to see what's currently available (this machine always has `macos` and `chrome`
as targets with no extra setup, since desktop/web don't need an emulator).

## Running on the Android emulator

One-time setup is already done on this machine (SDK, an AVD named `Medium_Phone_API_36.1`, licenses
accepted). The day-to-day loop:

**1. Launch the emulator** (a virtual phone window opens — leave it running in the background):
```
export ANDROID_HOME="$HOME/Library/Android/sdk"
"$ANDROID_HOME/emulator/emulator" -avd Medium_Phone_API_36.1 &
```
Or list/launch via Flutter's own wrapper: `flutter emulators` then `flutter emulators --launch Medium_Phone_API_36.1`.

**2. Wait for it to finish booting**, then confirm Flutter sees it:
```
export PATH="$HOME/development/flutter/bin:$ANDROID_HOME/platform-tools:$PATH"
flutter devices
```
You should see a line like `sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x64`.

**3. Run the app on it:**
```
flutter run -d emulator-5554
```
This does a full build (Gradle compiles the Android project, ~20-60s first time, faster after) and
installs the debug APK. Once it's running, the terminal is interactive:
- `r` — hot reload (pushes your latest code changes into the running app in ~1s, keeps app state)
- `R` — hot restart (re-runs `main()` fresh; needed after changing `main.dart`, providers, or anything
  hot reload can't patch — e.g. enum/class shape changes)
- `q` — quit and disconnect

**4. Making a change and seeing it:** edit code, save, press `r` in that terminal. If nothing seems to
update, try `R` (hot restart) — some changes (new dependencies, native/platform code, top-level state)
need a full restart, not just a reload.

## Building a release artifact

```
flutter build apk --release      # installable .apk, in build/app/outputs/flutter-apk/
flutter build appbundle --release  # .aab, what you'd upload to Google Play
```
For iOS (`flutter build ios`) or macOS/Windows/Linux desktop builds, the same `flutter build <platform>`
pattern applies — see `flutter build -h` for the full list of targets this project supports.

## Testing on a physical phone instead of the emulator

1. On the phone: Settings → About phone → tap "Build number" 7 times to enable Developer Options, then
   Settings → Developer options → enable **USB debugging**.
2. Plug it into this Mac via USB, accept the "Allow USB debugging?" prompt on the phone.
3. `flutter devices` should list it; `flutter run -d <device-id>` runs on it exactly like the emulator.
   A physical device is generally faster and more stable than the emulator, and is the only way to test
   things an emulator can't (real camera, real GPS, real performance).

## Troubleshooting

- **`flutter devices` doesn't show the emulator**: it's probably still booting — wait and retry, or check
  `adb devices -l` directly (states: `device` = ready, `offline`/blank = not ready yet).
- **`adb devices` shows the emulator `offline` and it won't clear**: usually host resource pressure (too
  many other apps/processes running). Check `uptime` for load average — if it's high, close other apps.
  As a last resort, `adb kill-server && adb start-server`, or fully restart the emulator (find its process
  with `ps aux | grep qemu`, kill it, relaunch per step 1 above).
- **`PostgrestException: JWT issued at future` (code `PGRST303`)**: the emulator's virtual clock has
  drifted from real time (happens on long-running emulator sessions) — restart the emulator; a fresh boot
  resyncs its clock from the host.
- **A newer plugin fails the Android build with a Gradle/`flutter.compileSdkVersion` error**: this
  project's Flutter version is pinned old (see top of this doc) — see the comment on `dependency_overrides`
  in `pubspec.yaml` for the known example (`app_links`) and how it was resolved.

## Tests

```
flutter test
```

Pure-logic tests (split calculation, debt simplification, model JSON round-trips) run with no network
dependency. Widget tests use `ProviderScope(overrides: [...])` to inject fake repositories.
