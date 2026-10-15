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
flutter test                      # unit tests (pure logic in lib/logic and lib/models)
flutter test test/click_guard_test.dart
flutter build apk --release
flutter build appbundle --release
flutter build linux --release
```

`pubspec.yaml` has `dependency_overrides` pinning `jni` 1.0.0 / `jni_flutter` 1.0.1, because `jni` 1.1.0 doesn't compile on Linux desktop. Remove the overrides once upstream fixes it.

### Required private files (gitignored)

- `lain_chikita/lib/private_keys.dart` defines `const SECRET_KEY` (AES key for redeem codes). The app won't compile without it.
- `lain_chikita/android/key.properties` and `key/keystore.jks` hold the release signing config. **Debug builds also use the release signing config** (`android/app/build.gradle.kts`), because Google Play Games Services needs the release SHA.

## Architecture (`lain_chikita/lib/`)

- `main.dart` loads everything before `runApp`: translations, then `GameState.load()` (which first runs the legacy-prefs migration), local achievements and audio.
- `state/game_state.dart`: `GameState` is a `ChangeNotifier` and the single source of truth for game data. Every mutation goes through its methods (`addLove`, `buyRandomAccessory`, `selectAccessory`, `applySaveData`, ...), which persist and call `notifyListeners()`. There's no state-management package: `GameState` is created in `main` and passed down by constructor, and widgets rebuild with `ListenableBuilder`.
- `services/` are singletons (`X.instance`):
  - `GameStorage` wraps preferences.
  - `PlayGamesService` wraps `games_services`. It's Android-only; on other platforms its methods are no-ops or return false/null, so callers don't check `Platform`.
  - `AchievementsService` handles achievements.
  - `AudioService` plays sounds.
  - `Translations` (with the `tr('key')` shortcut) holds UI text.
  - `RedeemCodeService` redeems codes.
  - `SaveFileService` handles `.save` backups (Linux/Windows only).
  - `crypto.dart` and `user_files.dart` are helpers.
- `logic/` holds pure, unit-tested code: `ClickGuard` (anti-cheat) and the inventory merge and JSON codec.
- `data/` holds static catalogs (accessories, redeem codes, achievements). `models/` holds `GameSaveData` and the sealed `RedeemResult`.
- `screens/home_screen.dart` is the `PageView` shell (love → inventory → gacha → game data). It also owns the anti-cheat block screen, the snow event and the "updated" animation. `widgets/` holds the shared `MenuButton` and `showConfirmDialog`.

Leveling works like this: there are 20 clicks per level (`GameState.lovePerLevel`). Every 50 levels advances the Play Games step achievements. Every 100 levels awards a coin, increments the cloud "cookies" leaderboard score and auto-saves to the cloud if signed in. Suspicious clicks still count; the anti-cheat only shows a 30 s block screen.

### Persistence: formats must stay backward compatible
- Local: `SharedPreferencesAsync` in `GameStorage`. It has no cache, so every getter is `await`ed, and it uses DataStore on Android. Key names live in `PrefsKeys` and must never be renamed. That includes `unlockedInventory`, which actually stores the **locked** accessories. The legacy `SharedPreferences` API is only used by `migrateLegacyIfNecessary()`, keyed by `legacyPrefsMigrationCompleted`.
- Cloud (Android only): Play Games slots `slot1` (`GameSaveData` JSON, where the inventories are JSON strings inside the JSON), `cookies_score` and `redeemed_codes` (`SaveSlots`).
- `.save` files (Linux/Windows only, user-chosen location via `file_selector`): `SaveFileData` is a `GameSaveData` plus the local achievements export, wrapped in `{format, formatVersion, savedAt}` and AES-encrypted with `SECRET_KEY`. If the structure changes, bump `SaveFileData.formatVersion` and keep reading older versions.
- Neither cloud saves nor `.save` files include coins: loading resets them to 0, which unlocks "I have lost it all" if the user had any.

### Platforms
- **Android**: Google Play Games for achievements, leaderboard, cloud save and redeem codes. Local data is stored in preferences.
- **Linux/Windows**: local achievements (`fifty_achievement_engine`, viewable in `LocalAchievementsScreen`) and `.save` backup/restore. Redeem codes need Play Games, so here "Let's All Love Lain" unlocks just by tapping the redeem button. `AchievementsService.syncLevel` raises the `level_up` stat to at least the current level, because the local engine was added after players already had levels.
- macOS/iOS aren't distributed.
- Accessory lists are stored as `[{"name": "<id>"}]` (`encodeAccessoryList`) but handled in memory as `List<String>`.

### Adding things
- **Accessory**:
  1. Add its id to `unlockableAccessories` in `data/accessories_catalog.dart` and **increment `inventoryVersion`**. On startup, a changed version merges new catalog items into the user's locked list and plays the "updated" animation.
  2. Add `assets/images/accessories/<id>.png`.
  3. Add its name to `assets/language/items_name_en.json` and `items_name_es.json`.
- **Event achievement**: add a value to the `GameAchievement` enum (local id + Play Console id), add a matching `fifty.Achievement` to `localAchievements`, and call `AchievementsService.instance.unlock(...)`. The service picks Play Games on Android and the local `fifty_achievement_engine` elsewhere.
- **Redeem code**: add it to `redeemableCodes` (`data/redeemable_codes.dart`). The user-facing code is `encryptData('{"id":"<id>"}', SECRET_KEY)` from `services/crypto.dart`. Redeeming requires a Play Games sign-in.
- **UI text**: add the key to both `assets/language/labels_en.json` and `labels_es.json`. `tr()` falls back to the key itself.
- Assets must be declared in `pubspec.yaml`. Paths are centralized in `core/app_assets.dart`, and colors in `core/app_colors.dart`.
