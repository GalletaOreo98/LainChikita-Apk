import 'dart:async' show Timer;

import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../data/achievements_catalog.dart';
import '../models/game_save_data.dart';
import '../services/achievements_service.dart';
import '../services/audio_service.dart';
import '../services/play_games_service.dart';
import '../services/translations.dart';
import '../state/game_state.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/menu_button.dart';

/// Pantalla de Google Play Games (sesión, logros, leaderboard) y de guardar/cargar progreso.
///
/// En Android el progreso se guarda/carga de la nube. En las demás plataformas no hay nube:
/// "guardar" solo desbloquea los logros locales correspondientes y guarda su progreso.
class GameDataScreen extends StatefulWidget {
  const GameDataScreen({super.key, required this.game});

  final GameState game;

  @override
  State<GameDataScreen> createState() => _GameDataScreenState();
}

class _GameDataScreenState extends State<GameDataScreen> {
  final _playGames = PlayGamesService.instance;
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

  Future<void> _saveProgress() async {
    final confirmed = await _confirm(
      title: tr('confirm-save-progress'),
      message: tr('save-progress-overwrite-alert'),
      confirmLabel: tr('save'),
    );
    if (!confirmed) return;

    try {
      _showMessage('${tr('packing-data')}...', working: true);
      if (_playGames.isAvailable) {
        await _saveProgressToCloud();
      } else {
        await _saveProgressLocally();
      }
      _showMessage(tr('save-progress-successful'), working: false, hideAfterSeconds: 4);
    } catch (e) {
      _showError('Error saving data: $e');
    }
  }

  Future<void> _saveProgressToCloud() async {
    final data = _game.toSaveData().encode();
    _showMessage('${tr('sending-data')}...');
    await _playGames.saveToSlot(SaveSlots.gameData, data);
    _showMessage(tr('data-sent'));
    await _achievements.unlock(GameAchievement.keepYourLoveSafe);
  }

  /// Sin nube no hay nada que guardar, solo se dan los logros (y se pierden las monedas, como al cargar en Android)
  Future<void> _saveProgressLocally() async {
    await _achievements.unlock(GameAchievement.welcomeToTheWired);
    await _achievements.unlock(GameAchievement.keepYourLoveSafe);
    if (_game.coins >= 1) {
      await _game.resetCoins();
      await _achievements.unlock(GameAchievement.iHaveLostItAll);
    }
    await _achievements.saveLocalProgress();
  }

  Future<void> _loadProgress() async {
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

  @override
  Widget build(BuildContext context) {
    final cloudAvailable = _playGames.isAvailable;

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(12.0),
      child: SingleChildScrollView(
        child: ListenableBuilder(
          listenable: _game,
          builder: (context, _) {
            // Sin nube (no Android) se puede "guardar" sin sesión
            final canSave = _game.hasUserName && (_isSignedIn || !cloudAvailable);

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
                  onPressed: _isSignedIn ? () => _openPlayGamesUi(_playGames.showAchievements) : null,
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
                const SizedBox(height: 8),
                MenuButton(
                  label: tr('save-progress'),
                  onPressed: canSave ? _saveProgress : null,
                  color: AppColors.saveProgressBtn,
                ),
                if (cloudAvailable) ...[
                  const SizedBox(height: 8),
                  MenuButton(
                    label: tr('load-progress'),
                    onPressed: _isSignedIn ? _loadProgress : null,
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
