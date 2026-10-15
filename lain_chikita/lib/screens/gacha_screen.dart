import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../data/achievements_catalog.dart';
import '../models/redeem_result.dart';
import '../services/achievements_service.dart';
import '../services/audio_service.dart';
import '../services/redeem_code_service.dart';
import '../services/translations.dart';
import '../state/game_state.dart';
import '../widgets/menu_button.dart';

/// Pantalla para comprar accesorios con monedas y canjear códigos
class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key, required this.game});

  final GameState game;

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> {
  late final RedeemCodeService _redeemCodeService = RedeemCodeService(widget.game);
  final _redeemCodeController = TextEditingController();
  final _audio = AudioService.instance;

  String _message = '';
  bool _isError = false;
  bool _showRedeemCodeInput = false;

  @override
  void dispose() {
    _redeemCodeController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _isError = isError;
    });
  }

  Future<void> _buyAccessory() async {
    final bought = await widget.game.buyRandomAccessory();
    if (bought) {
      _showMessage(tr('accessory-purchased'));
      _audio.playAccessoryBought();
    } else {
      _showMessage(tr('cannot-be-purchased'), isError: true);
    }
  }

  void _toggleRedeemCodeInput() {
    setState(() {
      _showRedeemCodeInput = !_showRedeemCodeInput;
      if (!_showRedeemCodeInput) {
        _redeemCodeController.clear();
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
  }

  Future<void> _redeemCode(String code) async {
    _redeemCodeController.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    _showMessage('${tr('processing-code')}...');

    final result = await _redeemCodeService.redeem(code);
    if (!mounted) return;
    setState(() => _showRedeemCodeInput = false);

    switch (result) {
      case AccessoryUnlocked(:final accessoryId):
        _showMessage('${tr('accessory-unlocked')}: \n${Translations.instance.accessoryName(accessoryId)}');
        _audio.playRedeemCodeSuccess();
      case AccessoryAlreadyOwned(:final accessoryId):
        _showMessage(
          '${tr('already-have-this-item')}: \n${Translations.instance.accessoryName(accessoryId)}',
          isError: true,
        );
      case NoAccessoriesLeft():
        _showMessage(tr('all-accessories-unlocked'), isError: true);
      case InvalidCode():
        _showMessage(tr('error-invalid-data'), isError: true);
      case CodeAlreadyRedeemed():
        _showMessage(tr('code-already-redeemed'), isError: true);
    }

    // Cualquier código válido de accesorio cuenta para el logro
    if (result is AccessoryUnlocked || result is AccessoryAlreadyOwned || result is NoAccessoriesLeft) {
      await AchievementsService.instance.unlock(GameAchievement.letsAllLoveLain);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            ListenableBuilder(listenable: widget.game, builder: (context, _) => _Wallet(widget.game)),
            const SizedBox(height: 32),
            MenuButton(
              label: tr('buy-accessory'),
              onPressed: _buyAccessory,
              padding: const EdgeInsets.all(20.0),
            ),
            const SizedBox(height: 16),
            MenuButton(
              label: tr('redeem-code'),
              onPressed: _toggleRedeemCodeInput,
              color: AppColors.secondaryBtn,
              padding: const EdgeInsets.all(20.0),
            ),
            if (_showRedeemCodeInput) ...[
              const SizedBox(height: 16),
              _RedeemCodeInput(controller: _redeemCodeController, onSubmitted: _redeemCode),
            ],
            const SizedBox(height: 16),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 25.0, color: _isError ? AppColors.errorText : AppColors.informativeText),
            ),
          ],
        ),
      ),
    );
  }
}

/// Monedas del usuario y cuántos accesorios le faltan
class _Wallet extends StatelessWidget {
  const _Wallet(this.game);

  final GameState game;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25.0, color: AppColors.primaryText);
    final lockedCount = game.lockedAccessories.length;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppImages.coin, width: 32, height: 32),
            Text(' x ${game.coins}', style: textStyle),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          lockedCount > 0 ? '${tr('locked-accessories')} x $lockedCount' : tr('all-accessories-unlocked'),
          textAlign: TextAlign.center,
          style: textStyle,
        ),
      ],
    );
  }
}

class _RedeemCodeInput extends StatelessWidget {
  const _RedeemCodeInput({required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.userInputText, fontSize: 35.0),
      decoration: InputDecoration(
        suffixIcon: IconButton(
          onPressed: () => onSubmitted(controller.text),
          icon: const Icon(Icons.done),
          color: AppColors.userInputText,
        ),
        labelText: tr('enter-code'),
        labelStyle: const TextStyle(color: AppColors.primaryText, fontSize: 20),
        floatingLabelAlignment: FloatingLabelAlignment.center,
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.focusItem)),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.userInputText)),
      ),
      onSubmitted: onSubmitted,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
    );
  }
}
