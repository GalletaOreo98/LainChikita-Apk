import 'package:flutter/material.dart';

import 'core/navigation.dart';
import 'screens/home_screen.dart';
import 'state/game_state.dart';

class LainChikitaApp extends StatelessWidget {
  const LainChikitaApp({super.key, required this.game, required this.catalogWasUpdated});

  final GameState game;
  final bool catalogWasUpdated;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lain Chikita',
      theme: ThemeData(fontFamily: 'monogram'),
      navigatorKey: rootNavigatorKey,
      home: HomeScreen(game: game, catalogWasUpdated: catalogWasUpdated),
    );
  }
}
