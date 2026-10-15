import 'dart:async' show unawaited;
import 'dart:math' show Random;

import 'package:flutter/foundation.dart' show ChangeNotifier, kDebugMode, debugPrint;

import '../data/accessories_catalog.dart';
import '../logic/inventory_rules.dart';
import '../models/game_save_data.dart';
import '../services/achievements_service.dart';
import '../services/crypto.dart';
import '../services/game_storage.dart';
import '../services/play_games_service.dart';
import '../services/user_files.dart';

enum LoveOutcome {
  /// Solo avanzó la barra de amor
  progress,

  /// Subió de nivel
  levelUp,

  /// Subió de nivel y además ganó una moneda
  levelUpWithCoin,
}

/// Estado del juego del usuario. Toda modificación pasa por aquí: se guarda en las
/// preferencias y se avisa a la UI con [notifyListeners].
class GameState extends ChangeNotifier {
  GameState({
    GameStorage? storage,
    AchievementsService? achievements,
    PlayGamesService? playGames,
    Random? random,
  })  : _storage = storage ?? GameStorage.instance,
        _achievements = achievements ?? AchievementsService.instance,
        _playGames = playGames ?? PlayGamesService.instance,
        _random = random ?? Random.secure();

  final GameStorage _storage;
  final AchievementsService _achievements;
  final PlayGamesService _playGames;
  final Random _random;

  /// Clics de amor necesarios para subir un nivel
  static const int lovePerLevel = 20;

  /// Cada cuántos niveles se gana una moneda (y se guarda en la nube)
  static const int _coinEveryLevels = 100;

  /// Nombre que tiene el usuario mientras no haya elegido uno
  static const String defaultUserName = 'NULLUSER';

  String _userUuid = '';
  String _userSecretKey = '';
  String _userIv = '';
  String _userName = defaultUserName;
  int _level = 0;
  int _progress = 0;
  int _coins = 0;
  String _accessoryId = noAccessoryId;
  List<String> _inventory = [...starterAccessories];
  List<String> _lockedAccessories = [...unlockableAccessories];

  String get userName => _userName;
  bool get hasUserName => _userName != defaultUserName;
  int get level => _level;
  int get progress => _progress;

  /// Avance de la barra de amor, de 0 a 1
  double get levelProgress => _progress / lovePerLevel;
  int get coins => _coins;
  String get accessoryId => _accessoryId;

  /// Accesorios que tiene el usuario
  List<String> get inventory => List.unmodifiable(_inventory);

  /// Accesorios que le faltan por desbloquear
  List<String> get lockedAccessories => List.unmodifiable(_lockedAccessories);

  /// Carga el juego guardado. Devuelve true si el catálogo de accesorios cambió desde la
  /// última vez (para mostrar la animación de "actualizado").
  Future<bool> load() async {
    await _storage.migrateLegacyIfNecessary();
    final stored = await _storage.load();

    await _loadOrCreateCredentials(stored);

    _inventory = stored.inventory ?? [...starterAccessories];
    _lockedAccessories = stored.lockedAccessories ?? [...unlockableAccessories];
    final catalogChanged = stored.inventoryVersion != inventoryVersion;
    if (catalogChanged) {
      _lockedAccessories = mergeNewCatalogAccessories(
        catalog: unlockableAccessories,
        owned: _inventory,
        locked: _lockedAccessories,
      );
      await _storage.saveInventoryVersion(inventoryVersion);
      await _saveInventories();
    }

    _level = stored.level ?? 0;
    _progress = stored.progress ?? 0;
    _userName = stored.userName ?? defaultUserName;
    _accessoryId = stored.accessoryId ?? noAccessoryId;
    _coins = stored.coins ?? 0;

    if (hasUserName) _writeThankYouFile();
    notifyListeners();
    return catalogChanged;
  }

  /// Suma un clic de amor
  LoveOutcome addLove() {
    var outcome = LoveOutcome.progress;
    _progress++;

    if (_progress >= lovePerLevel) {
      _progress = 0;
      _level++;
      outcome = LoveOutcome.levelUp;
      unawaited(_achievements.onLevelUp(_level));

      if (_level % _coinEveryLevels == 0) {
        _coins++;
        outcome = LoveOutcome.levelUpWithCoin;
        unawaited(_playGames.incrementCookiesScore());
        unawaited(_autoSaveToCloud());
      }
    }

    unawaited(_saveProgress());
    notifyListeners();
    return outcome;
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    notifyListeners();
    _writeThankYouFile();
    await _saveProgress();
  }

  Future<void> selectAccessory(String accessoryId) async {
    _accessoryId = accessoryId;
    notifyListeners();
    await _storage.saveAccessory(accessoryId);
  }

  /// Cambia el orden del inventario (el usuario arrastra los accesorios para poner sus favoritos arriba).
  /// Los índices son los de `ReorderableListView.onReorder`
  Future<void> reorderInventory(int oldIndex, int newIndex) async {
    _inventory = moveAccessory(_inventory, oldIndex, newIndex);
    notifyListeners();
    await _saveInventories();
  }

  /// Gasta una moneda en un accesorio aleatorio. Devuelve false si no hay monedas o no quedan accesorios
  Future<bool> buyRandomAccessory() async {
    if (_coins <= 0 || _lockedAccessories.isEmpty) return false;
    _coins--;
    _unlockAt(_random.nextInt(_lockedAccessories.length));
    notifyListeners();
    await _storage.saveCoins(_coins);
    await _saveInventories();
    return true;
  }

  /// Desbloquea un accesorio aleatorio gratis. Devuelve su id, o null si ya no quedan
  Future<String?> unlockRandomAccessory() async {
    if (_lockedAccessories.isEmpty) return null;
    final accessoryId = _unlockAt(_random.nextInt(_lockedAccessories.length));
    notifyListeners();
    await _saveInventories();
    return accessoryId;
  }

  /// Desbloquea un accesorio específico. Devuelve false si no estaba bloqueado (ya lo tiene)
  Future<bool> unlockAccessory(String accessoryId) async {
    final index = _lockedAccessories.indexOf(accessoryId);
    if (index == -1) return false;
    _unlockAt(index);
    notifyListeners();
    await _saveInventories();
    return true;
  }

  Future<void> resetCoins() async {
    _coins = 0;
    notifyListeners();
    await _storage.saveCoins(0);
  }

  GameSaveData toSaveData() {
    return GameSaveData(
      userName: _userName,
      userUuid: _userUuid,
      level: _level,
      progress: _progress,
      userIv: _userIv,
      userSecretKey: _userSecretKey,
      accessoryId: _accessoryId,
      inventoryVersion: inventoryVersion,
      inventory: [..._inventory],
      lockedAccessories: [..._lockedAccessories],
    );
  }

  /// Reemplaza el juego actual por uno cargado de la nube. Las monedas se pierden (quedan en 0).
  Future<void> applySaveData(GameSaveData data) async {
    _userName = data.userName;
    _userUuid = data.userUuid;
    _userSecretKey = data.userSecretKey;
    _userIv = data.userIv;
    _level = data.level;
    _progress = data.progress;
    _coins = 0;
    _accessoryId = data.accessoryId;
    _inventory = [...data.inventory];
    _lockedAccessories = data.inventoryVersion == inventoryVersion
        ? [...data.lockedAccessories]
        : mergeNewCatalogAccessories(
            catalog: unlockableAccessories,
            owned: data.inventory,
            locked: data.lockedAccessories,
          );
    notifyListeners();

    await _saveProgress();
    await _saveCredentials();
    await _storage.saveAccessory(_accessoryId);
    await _storage.saveInventoryVersion(inventoryVersion);
    await _saveInventories();
  }

  Future<void> _loadOrCreateCredentials(StoredGame stored) async {
    String? nonEmpty(String? value) => (value == null || value.isEmpty) ? null : value;

    final storedUuid = nonEmpty(stored.userUuid);
    final storedSecretKey = nonEmpty(stored.userSecretKey);
    final storedIv = nonEmpty(stored.userIv);

    _userUuid = storedUuid ?? generateCryptoRngUuid();
    _userSecretKey = storedSecretKey ?? generateUserSecretKey(32);
    _userIv = storedIv ?? generateUserIv(16);

    if (storedUuid == null || storedSecretKey == null || storedIv == null) await _saveCredentials();
  }

  String _unlockAt(int lockedIndex) {
    final accessoryId = _lockedAccessories.removeAt(lockedIndex);
    _inventory.add(accessoryId);
    return accessoryId;
  }

  /// Guarda en la nube solo si el usuario ya tiene sesión en Play Games
  Future<void> _autoSaveToCloud() async {
    try {
      if (!await _playGames.isSignedIn()) return;
      await _playGames.saveToSlot(SaveSlots.gameData, toSaveData().encode());
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving game data to Google Play Games: $e');
    }
  }

  void _writeThankYouFile() {
    writeThankYouFile(_userName).catchError((Object e) {
      if (kDebugMode) debugPrint('Error writing THANKS.txt: $e');
    });
  }

  Future<void> _saveProgress() =>
      _storage.saveProgress(level: _level, progress: _progress, userName: _userName, coins: _coins);

  Future<void> _saveCredentials() =>
      _storage.saveCredentials(userUuid: _userUuid, userSecretKey: _userSecretKey, userIv: _userIv);

  Future<void> _saveInventories() =>
      _storage.saveInventories(inventory: _inventory, lockedAccessories: _lockedAccessories);
}
