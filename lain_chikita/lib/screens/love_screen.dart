import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../services/translations.dart';
import '../state/game_state.dart';

/// Pantalla principal: Lain Chikita, su accesorio, el nombre del usuario y la barra de amor.
/// Si el usuario aún no tiene nombre, se le pide uno.
class LoveScreen extends StatelessWidget {
  const LoveScreen({
    super.key,
    required this.game,
    required this.backgroundImage,
    required this.showUpdatedAnimation,
    required this.onLove,
  });

  final GameState game;
  final String backgroundImage;
  final bool showUpdatedAnimation;
  final VoidCallback onLove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(backgroundImage), fit: BoxFit.cover),
      ),
      child: ListenableBuilder(
        listenable: game,
        builder: (context, _) => Stack(
          children: [
            if (game.hasUserName) ...[
              _UserNameLabel(game.userName),
              const _CharacterImage(AppImages.lainChikita),
              Positioned(
                child: Center(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: onLove,
                      child: _CharacterImage(AppImages.accessory(game.accessoryId)),
                    ),
                  ),
                ),
              ),
            ] else
              _UserNameInput(onSubmitted: game.setUserName),
            if (showUpdatedAnimation)
              Positioned(
                child: Center(
                  child: GestureDetector(
                    onTap: onLove,
                    child: Image.asset(AppImages.updated, fit: BoxFit.cover),
                  ),
                ),
              ),
            _LevelBar(game),
          ],
        ),
      ),
    );
  }
}

class _UserNameLabel extends StatelessWidget {
  const _UserNameLabel(this.userName);

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(userName, style: const TextStyle(fontSize: 48.0, color: AppColors.nameLabel)),
      ),
    );
  }
}

class _UserNameInput extends StatefulWidget {
  const _UserNameInput({required this.onSubmitted});

  final ValueChanged<String> onSubmitted;

  @override
  State<_UserNameInput> createState() => _UserNameInputState();
}

class _UserNameInputState extends State<_UserNameInput> {
  final _controller = TextEditingController(text: GameState.defaultUserName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String name) {
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onSubmitted(name);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          textAlign: TextAlign.center,
          maxLength: 15,
          style: const TextStyle(color: AppColors.nameLabel, fontSize: 34.0),
          decoration: InputDecoration(
            suffixIcon: IconButton(
              onPressed: () => _submit(_controller.text),
              icon: const Icon(Icons.done),
              color: AppColors.focusItem,
            ),
            labelText: tr('new-user-name'),
            labelStyle: const TextStyle(color: AppColors.primaryText, fontSize: 34.0),
            floatingLabelAlignment: FloatingLabelAlignment.center,
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.focusItem)),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.userInputText)),
          ),
          onSubmitted: _submit,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        ),
      ],
    );
  }
}

/// Imagen centrada de Lain o de su accesorio (las dos capas tienen el mismo tamaño y posición)
class _CharacterImage extends StatelessWidget {
  const _CharacterImage(this.asset);

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 30),
        child: Transform.translate(
          offset: const Offset(0, -30),
          child: Image.asset(asset, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar(this.game);

  final GameState game;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.sizeOf(context).height * 0.05),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${tr('level')} ${game.level}',
              style: const TextStyle(fontSize: 40.0, color: AppColors.primaryText),
            ),
            if (game.hasUserName) ...[
              const SizedBox(height: 8.0),
              SizedBox(
                height: 16.0,
                width: 250.0,
                child: LinearProgressIndicator(
                  value: game.levelProgress,
                  backgroundColor: AppColors.loveBarOpposite,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.loveBar),
                ),
              ),
              const SizedBox(height: 34.0),
            ],
          ],
        ),
      ),
    );
  }
}
