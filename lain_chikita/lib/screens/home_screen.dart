import 'dart:async' show Timer, unawaited;
import 'dart:math' show Random;

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent, KeyEvent, LogicalKeyboardKey;

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../data/achievements_catalog.dart';
import '../logic/click_guard.dart';
import '../services/achievements_service.dart';
import '../services/audio_service.dart';
import '../state/game_state.dart';
import 'gacha_screen.dart';
import 'game_data_screen.dart';
import 'inventory_screen.dart';
import 'love_screen.dart';

/// Contenedor de las pantallas (se cambia entre ellas deslizando o con las flechas del teclado).
/// También se encarga del anti-cheat, la nieve de evento especial y la animación de "actualizado".
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.game, required this.catalogWasUpdated});

  final GameState game;

  /// Si es true se muestra la animación de "actualizado" al iniciar
  final bool catalogWasUpdated;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _pageTransitionDuration = Duration(milliseconds: 300);
  static const _updatedAnimationDuration = Duration(seconds: 5);
  static const _antiCheatBlockDuration = Duration(seconds: 30);

  /// El fondo de tramposo se queda un rato más después de quitar el bloqueo
  static const _cheaterBackgroundDuration = Duration(seconds: 46);

  final _pageController = PageController();
  final _focusNode = FocusNode();
  final _clickGuard = ClickGuard();
  final _audio = AudioService.instance;

  /// 1 de cada 10 veces que se abre la app cae nieve
  final bool _showSnow = Random.secure().nextInt(10) == 3;
  String _background = _backgroundForCurrentHour();
  bool _showUpdatedAnimation = false;
  bool _isBlocked = false;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    if (widget.catalogWasUpdated) _startUpdatedAnimation();
    unawaited(AchievementsService.instance.refreshPlayGamesAchievements());
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  static String _backgroundForCurrentHour() {
    final hour = DateTime.now().hour;
    return (hour >= 5 && hour < 18) ? AppImages.backgroundDay : AppImages.backgroundNight;
  }

  void _after(Duration duration, VoidCallback callback) {
    _timers.add(Timer(duration, () {
      if (mounted) callback();
    }));
  }

  void _startUpdatedAnimation() {
    setState(() => _showUpdatedAnimation = true);
    _audio.playUpdated();
    _after(_updatedAnimationDuration, () => setState(() => _showUpdatedAnimation = false));
  }

  void _onLove() {
    final verdict = _clickGuard.check(DateTime.now().millisecondsSinceEpoch);
    if (verdict == ClickVerdict.triggeredBlock) _showAntiCheatBlock();
    if (verdict != ClickVerdict.valid && kDebugMode) {
      debugPrint('Clic sospechoso detectado por el anti-cheat (${_clickGuard.suspiciousClickCount})');
    }
    // OJO: los clics sospechosos igual cuentan; el castigo es la pantalla de bloqueo

    _audio.playLoveButton();
    final outcome = widget.game.addLove();
    if (outcome == LoveOutcome.levelUpWithCoin) _audio.playLevelUp();
  }

  void _showAntiCheatBlock() {
    _audio.playCheaterScreen();
    setState(() {
      _background = AppImages.backgroundCheater;
      _isBlocked = true;
    });
    _after(_antiCheatBlockDuration, () {
      _clickGuard.unblock();
      setState(() => _isBlocked = false);
    });
    _after(_cheaterBackgroundDuration, () => setState(() => _background = _backgroundForCurrentHour()));
    AchievementsService.instance.unlock(GameAchievement.godIsWatchingYou);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _pageController.nextPage(duration: _pageTransitionDuration, curve: Curves.ease);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _pageController.previousPage(duration: _pageTransitionDuration, curve: Curves.ease);
    }
  }

  void _goToLoveScreen() {
    _pageController.animateToPage(0, duration: _pageTransitionDuration, curve: Curves.ease);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          KeyboardListener(
            focusNode: _focusNode,
            onKeyEvent: _handleKeyEvent,
            child: PageView(
              controller: _pageController,
              children: [
                LoveScreen(
                  game: widget.game,
                  backgroundImage: _background,
                  showUpdatedAnimation: _showUpdatedAnimation,
                  onLove: _onLove,
                ),
                InventoryScreen(game: widget.game, onAccessorySelected: _goToLoveScreen),
                GachaScreen(game: widget.game),
                GameDataScreen(game: widget.game),
              ],
            ),
          ),
          if (_showSnow)
            IgnorePointer(child: Image.asset(AppImages.snowing, fit: BoxFit.cover)),
          // Va al final para quedar encima de todo
          if (_isBlocked) const _AntiCheatBlockScreen(),
        ],
      ),
    );
  }
}

class _AntiCheatBlockScreen extends StatelessWidget {
  const _AntiCheatBlockScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(AppImages.backgroundCheater), fit: BoxFit.cover),
      ),
      child: const Center(
        child: Text(
          "God is watching you \n But you don't need to be afraid",
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.errorText),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
