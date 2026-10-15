# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Lain Chikita: a small Flutter clicker/"give love" minigame published on Google Play (`com.oreodev.lain_chikita`). The Flutter project lives in `lain_chikita/`; the repo root also hosts the GitHub Pages site (`CNAME`, `_config.yml`, `demo/privacy_policy/`, `.well-known/assetlinks.json`). Code comments and commit messages are mostly in Spanish (commit style: `UPDATE: ...`, `REFACTOR: ...`).

## Commands

Run everything from `lain_chikita/`:

```bash
flutter pub get
flutter run                       # debug run
flutter analyze                   # lint (flutter_lints, see analysis_options.yaml)
flutter test                      # tests
flutter test test/widget_test.dart
flutter build apk --release
flutter build appbundle --release
```

`test/widget_test.dart` is still the default Flutter counter template and does not reflect the app; it asserts a counter UI that doesn't exist, so expect it to fail.

### Required private files (gitignored)

- `lain_chikita/lib/private_keys.dart` defines `const SECRET_KEY` (AES key used for backups and redeem codes). The app won't compile without it.
- `lain_chikita/android/key.properties` and `key/keystore.jks` hold the release signing config. **Debug builds also use the release signing config** (`android/app/build.gradle.kts`), because Google Play Games Services needs the release SHA.

## Architecture

### Global state
There is no state-management library. All game state lives as top-level mutable variables in `lib/global_vars.dart` (level, progress, coins, userName, inventories, language, singletons like `languageDataManager`, `appAudioPlayer`). Import it as `import '../global_vars.dart' as global_vars;` (optionally with `show ...`). Screens mutate these globals directly and call `setState`.

`lib/main.dart` holds `_MyHomePageState`, which does most of the work: `_loadProgress()` bootstraps everything from `SharedPreferences` on startup, and it also contains save functions, the anti-cheat click limiter, and the level-up loop. Leveling works like this: `_maxProgress` = 20 clicks per level, every 50 levels advances the step achievements, and every 100 levels awards a coin, increments the cloud "cookies" leaderboard score and saves to the cloud. The other screens (`inventory_screen`, `gacha_screen`, `game_data_screen`) are pages in a `PageView`.

### Persistence
- Local: `SharedPreferencesAsync` through the global `appPrefs` in `functions/prefs_storage.dart`. It has no cache, so every getter is `await`ed, and it uses DataStore on Android. Don't use the legacy `SharedPreferences` API. Its only remaining use is `migrateLegacyPrefsIfNecessary()`, which runs at the start of `_loadProgress()` to copy data from older app versions, keyed by `legacyPrefsMigrationCompleted`. Never rename or delete that key. Keys used: (`level`, `progress`, `userName`, `coins`, `accessoryName`, `inventory`, `unlockedInventory`, `inventoryVersion`, `userUuid`, `userSecretKey`, `userIv`, `achievement_progress_engine_data`).
- Cloud (Android only): Google Play Games `SaveGame` slots `slot1` (full game data JSON), `cookies_score`, and `redeemed_codes`.

### Inventory / accessories (skins)
- `inventory` is the list of owned accessories. `unlockedInventory` (despite the name) is the list of accessories **not yet owned**, from which the gacha draws.
- **Adding a new accessory** requires all of the following:
  1. Add `{'name': '<id>'}` to `unlockedInventory` in `global_vars.dart`.
  2. **Increment `inventoryVersion`.** On startup, `applyInventoryVerionUpdate` (`functions/prefs_version_manager.dart`) merges new app items into the user's saved not-owned list only when the version changed, and then plays the "updated" animation.
  3. Add `assets/images/accessories/<id>.png` (rendered as `assets/images/accessories/${accessoryName}.png`).
  4. Add the display name to both `assets/language/items_name_en.json` and `items_name_es.json`.

### i18n
`LanguageDataManager` loads `assets/language/labels_<lang>.json` and `items_name_<lang>.json` (`en`/`es`, picked from the device locale in `main()`). UI text uses `languageDataManager.getLabel('key')`, which falls back to the key itself. Any new label needs both language files.

### Achievements: two parallel systems
`functions/achievements_manager.dart`:
- **Android**: Google Play Games Services (`games_services`), with achievements referenced by Play Console IDs like `"CgkI8NLzkooQEAIQBg"` through `unlockAchievementById` and `incrementAchievementsStepType`. These functions return early on non-Android platforms.
- **Other platforms**: the local `fifty_achievement_engine`. Definitions live in `lib/data/game_achievements.dart`, and the `achievementController` is driven by `incrementStat('level_up', 1)` / `forceUnlock('<local_id>')`. Progress is exported to SharedPreferences (`achievement_progress_engine_data`) and shows a popup through the global `appContext`.

Call sites usually do both: `if (!Platform.isAndroid) achievementController.forceUnlock('local_id');` followed by `unlockAchievementById("<play id>");`. A new achievement needs an entry in each system.

### Redeem codes
Codes are AES-encrypted JSON (`{'id': ...}`) decrypted with `SECRET_KEY` in `functions/redeem_codes_functions.dart`. Valid codes and their effects are whitelisted in `redeemableCodes` in `global_vars.dart` (typed by the `RedeemableCodeType` enum, stored as `.name`). Redeeming requires a Google Play Games sign-in, and redeemed IDs are tracked in the cloud slot `redeemed_codes`.

### Other
- `functions/encryption_functions.dart`: AES helpers (`encryptData`/`decryptData`) plus isolate-based file encryption of the app's `FILES_TO_ENCRYPT` → `ENCRYPTED_FILES` / `DECRYPTED_FILES` folders (`AppFolders`, under external storage on Android). The UI for file encryption and clipboard backup is currently commented out in `game_data_screen.dart`.
- `gacha_functions.dart` uses `Random.secure()` for draws and accessory unlocks.
- Assets must be declared in `pubspec.yaml`. The accessory, audio and language folders are declared as directories, but top-level images are listed individually.
