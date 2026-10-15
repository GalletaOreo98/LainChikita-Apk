import 'dart:async' show Timer;

import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../data/achievements_catalog.dart';
import '../models/game_save_data.dart';
import '../models/save_file_data.dart';
import '../services/achievements_service.dart';
import '../services/audio_service.dart';
import '../services/play_games_service.dart';
import '../services/save_file_service.dart';
import '../services/translations.dart';
import '../state/game_state.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/menu_button.dart';
import 'local_achievements_screen.dart';

/// Pantalla de logros y de guardar/cargar progreso.
///
/// - Android: Google Play Games (sesión, logros, leaderboard y guardado en la nube).
/// - Linux y Windows: logros locales y respaldo en un archivo .save que el usuario guarda donde quiera.
class GameDataScreen extends StatefulWidget {
  const GameDataScreen({super.key, required this.game});

  final GameState game;

  @override
  State<GameDataScreen> createState() => _GameDataScreenState();
}

class _GameDataScreenState extends State<GameDataScreen> {
  final _playGames = PlayGamesService.instance;
  final _saveFiles = SaveFileService.instance;
  final _achievements = AchievementsService.instance;
  final _audio = AudioService.instance;

  String _message = '';
  bool _isWorking = false;
  bool _isSignedIn = false;
  Timer? _hideMessageTimer;

  GameState get _game => widget.game;

  @override
  void initState() {
    super.initState();
    _refreshSignInStatus();
  }

  @override
  void dispose() {
    _hideMessageTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshSignInStatus() async {
    final isSignedIn = await _playGames.isSignedIn();
    if (mounted) setState(() => _isSignedIn = isSignedIn);
  }

  /// Muestra [message] en la parte de abajo. Si se da [hideAfterSeconds], se borra solo después de ese tiempo
  void _showMessage(String message, {bool? working, int? hideAfterSeconds}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      if (working != null) _isWorking = working;
    });
    _hideMessageTimer?.cancel();
    if (hideAfterSeconds != null) {
      _hideMessageTimer = Timer(Duration(seconds: hideAfterSeconds), () {
        if (mounted) setState(() => _message = '');
      });
    }
  }

  void _showError(String message) => _showMessage(message, working: false, hideAfterSeconds: 5);

  Future<void> _signIn() async {
    try {
      await _playGames.signIn();
      await _refreshSignInStatus();
      _showMessage('${tr('completed').toUpperCase()}: Game Services Sign In', hideAfterSeconds: 3);
    } catch (e) {
      _showError('Error: $e');
    }
  }

  /// Abre una UI nativa de Play Games (logros o leaderboard)
  Future<void> _openPlayGamesUi(Future<void> Function() open) async {
    _audio.playInformativePopup();
    _showMessage('${tr('loading')}...', working: true);
    try {
      await open();
      _showMessage(_message, working: false, hideAfterSeconds: 3);
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<bool> _confirm({required String title, required String message, required String confirmLabel}) async {
    _audio.playInformativePopup();
    final confirmed = await showConfirmDialog(context, title: title, message: message, confirmLabel: confirmLabel);
    if (confirmed) {
      _audio.playAcceptPopup();
    } else {
      _audio.playCancel();
    }
    return confirmed;
  }

  void _openLocalAchievements() {
    _audio.playInformativePopup();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LocalAchievementsScreen()));
  }

  // ---------------------------------------------------------------------------
  // Android: nube de Google Play Games
  // ---------------------------------------------------------------------------

  Future<void> _saveProgressToCloud() async {
    final confirmed = await _confirm(
      title: tr('confirm-save-progress'),
      message: tr('save-progress-overwrite-alert'),
      confirmLabel: tr('save'),
    );
    if (!confirmed) return;

    try {
      _showMessage('${tr('packing-data')}...', working: true);
      final data = _game.toSaveData().encode();
      _showMessage('${tr('sending-data')}...');
      await _playGames.saveToSlot(SaveSlots.gameData, data);
      _showMessage(tr('data-sent'));
      await _achievements.unlock(GameAchievement.keepYourLoveSafe);
      _showMessage(tr('save-progress-successful'), working: false, hideAfterSeconds: 4);
    } catch (e) {
      _showError('Error saving data: $e');
    }
  }

  Future<void> _loadProgressFromCloud() async {
    final confirmed = await _confirm(
      title: tr('confirm-load-progress'),
      message: tr('load-progress-overwrite-alert'),
      confirmLabel: tr('load'),
    );
    if (!confirmed) return;

    try {
      _showMessage('${tr('receiving-data')}...', working: true);
      final encoded = await _playGames.loadFromSlot(SaveSlots.gameData);
      _showMessage(tr('data-received'));
      if (encoded == null) {
        _showError('Error: No saved data found.');
        return;
      }

      _showMessage('${tr('ordering-data')}...');
      final saveData = GameSaveData.decode(encoded);

      _showMessage('${tr('applying-data')}...');
      final hadCoins = _game.coins >= 1;
      await _game.applySaveData(saveData);

      _showMessage('${tr('loading-achievements')}...');
      await _achievements.refreshPlayGamesAchievements();
      await _achievements.unlock(GameAchievement.welcomeToTheWired);
      if (hadCoins) await _achievements.unlock(GameAchievement.iHaveLostItAll);

      _showMessage('${tr('load-progress-successful')}\n${tr('restart-your-app')}', working: false);
    } catch (e) {
      _showError('Error loading data: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Linux y Windows: respaldo en archivo .save
  // ---------------------------------------------------------------------------

  Future<void> _saveProgressToFile() async {
    _audio.playInformativePopup();
    final String? path;
    try {
      path = await _saveFiles.pickSaveLocation();
    } catch (e) {
      _showError('Error: $e');
      return;
    }
    if (path == null) {
      _audio.playCancel();
      return;
    }
    _audio.playAcceptPopup();

    try {
      _showMessage('${tr('packing-data')}...', working: true);
      // Se desbloquea antes de escribir para que el logro también quede dentro del respaldo
      await _achievements.unlock(GameAchievement.keepYourLoveSafe);
      await _saveFiles.write(
        path,
        SaveFileData(
          game: _game.toSaveData(),
          localAchievements: _achievements.exportLocalProgress(),
          savedAt: DateTime.now(),
        ),
      );
      _showMessage(tr('save-progress-successful'), working: false, hideAfterSeconds: 4);
    } catch (e) {
      _showError('Error saving data: $e');
    }
  }

  Future<void> _loadProgressFromFile() async {
    final confirmed = await _confirm(
      title: tr('confirm-load-progress'),
      message: tr('load-from-file-overwrite-alert'),
      confirmLabel: tr('load'),
    );
    if (!confirmed) return;

    final SaveFileData? saveFile;
    try {
      saveFile = await _saveFiles.pickAndRead();
    } on FormatException {
      _showError(tr('invalid-save-file'));
      return;
    } catch (e) {
      _showError('Error loading data: $e');
      return;
    }
    if (saveFile == null) {
      _audio.playCancel();
      return;
    }

    try {
      _showMessage('${tr('applying-data')}...', working: true);
      final hadCoins = _game.coins >= 1;
      await _game.applySaveData(saveFile.game);

      _showMessage('${tr('loading-achievements')}...');
      await _achievements.replaceLocalProgress(saveFile.localAchievements);
      await _achievements.syncLevel(_game.level);
      await _achievements.unlock(GameAchievement.welcomeToTheWired);
      if (hadCoins) await _achievements.unlock(GameAchievement.iHaveLostItAll);

      _showMessage(tr('load-progress-successful'), working: false, hideAfterSeconds: 4);
    } catch (e) {
      _showError('Error loading data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cloudAvailable = _playGames.isAvailable;
    final fileBackupAvailable = !cloudAvailable && _saveFiles.isAvailable;

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(12.0),
      child: SingleChildScrollView(
        child: ListenableBuilder(
          listenable: _game,
          builder: (context, _) {
            final hasUserName = _game.hasUserName;

            return Column(
              children: [
                if (cloudAvailable) ...[
                  const SizedBox(height: 8),
                  MenuButton(
                    label: _isSignedIn ? tr('connected') : tr('connect-with-google'),
                    onPressed: _isSignedIn ? null : _signIn,
                    color: AppColors.signInBtn,
                    disabledColor: AppColors.signInBtnDisabled,
                    disabledTextColor: AppColors.primaryText,
                  ),
                ],
                const SizedBox(height: 8),
                MenuButton(
                  label: tr('achievements'),
                  onPressed: cloudAvailable
                      ? (_isSignedIn ? () => _openPlayGamesUi(_playGames.showAchievements) : null)
                      : _openLocalAchievements,
                  color: AppColors.achievementsBtn,
                ),
                if (cloudAvailable) ...[
                  const SizedBox(height: 8),
                  MenuButton(
                    label: tr('leaderboards'),
                    onPressed: _isSignedIn ? () => _openPlayGamesUi(_playGames.showCookiesLeaderboard) : null,
                    color: AppColors.leaderboardsBtn,
                  ),
                ],
                if (cloudAvailable || fileBackupAvailable) ...[
                  const SizedBox(height: 8),
                  MenuButton(
                    label: tr('save-progress'),
                    onPressed: !hasUserName
                        ? null
                        : cloudAvailable
                            ? (_isSignedIn ? _saveProgressToCloud : null)
                            : _saveProgressToFile,
                    color: AppColors.saveProgressBtn,
                  ),
                  const SizedBox(height: 8),
                  MenuButton(
                    label: tr('load-progress'),
                    // Cargar un .save no pide nombre: es justo lo que hace alguien que reinstaló la app
                    onPressed: cloudAvailable ? (_isSignedIn ? _loadProgressFromCloud : null) : _loadProgressFromFile,
                    color: AppColors.loadProgressBtn,
                  ),
                ],
                const SizedBox(height: 16),
                if (_isWorking) Image.asset(AppImages.working),
                const SizedBox(height: 8),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32.0, color: AppColors.informativeText),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
