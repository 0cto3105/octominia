// lib/screens/games/game_center.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:octominia/models/game.dart';
import 'package:octominia/services/game_json_storage.dart';
import 'package:octominia/screens/games/game_setup_screen.dart';
import 'package:octominia/screens/games/game_roll_offs_screen.dart';
import 'package:octominia/screens/games/game_round_screen.dart';
import 'package:octominia/screens/games/game_summary_screen.dart';
import 'package:octominia/screens/games/game_template.dart';

class GamerCenterScreen extends StatefulWidget {
  final Game? initialGame;
  final Function(Game game) onGameSaved;

  const GamerCenterScreen({
    super.key,
    this.initialGame,
    required this.onGameSaved,
  });

  @override
  State<GamerCenterScreen> createState() => _GamerCenterScreenState();
}

class _GamerCenterScreenState extends State<GamerCenterScreen> {
  late PageController _pageController;
  late Game _game;
  final GameJsonStorage _gameStorage = GameJsonStorage();
  bool _gameHasBeenSavedOnce = false;

  @override
  void initState() {
    super.initState();
    
    _game = widget.initialGame ?? Game(
      date: DateTime.now(),
      myPlayerName: 'Joueur 1',
      myFactionName: '',
      myDrops: 1,
      myAuxiliaryUnits: false,
      opponentPlayerName: 'Joueur 2',
      opponentFactionName: '',
      opponentDrops: 1,
      opponentAuxiliaryUnits: false,
    );
    
    _gameHasBeenSavedOnce = widget.initialGame != null;

    if (widget.initialGame != null) {
        // CORRECTION : On appelle la méthode maintenant publique
        _game = _game.recalculateStateFromRound(1);
    }
    
    int startingPageIndex = _getPageIndexForGameState(_game.gameState);
    _pageController = PageController(initialPage: startingPageIndex);
  }

  int _getPageIndexForGameState(GameState state) {
    switch (state) {
        case GameState.setup: return 0;
        case GameState.rollOffs: return 1;
        case GameState.round1: return 2;
        case GameState.round2: return 3;
        case GameState.round3: return 4;
        case GameState.round4: return 5;
        case GameState.round5: return 6;
        case GameState.summary:
        case GameState.completed:
          return 7;
        default: return 0;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _updateAndSaveGame(Game updatedGame) {
    setState(() {
      _game = updatedGame;
    });
    _saveGame();
  }

  Future<void> _saveGame() async {
    try {
      if (!_gameHasBeenSavedOnce) {
        await _gameStorage.addGame(_game);
        _gameHasBeenSavedOnce = true;
      } else {
        await _gameStorage.updateGame(_game);
      }
      widget.onGameSaved(_game);
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de sauvegarde: $e')),
        );
      }
    }
  }
  
  void _goToPage(int pageIndex) {
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }
  
  void _nextPage() {
    int currentPageIndex = _pageController.page!.round();
    if (currentPageIndex < 7) {
      _goToPage(currentPageIndex + 1);
    }
  }

  void _previousPage() {
    int currentPageIndex = _pageController.page!.round();
    if (currentPageIndex > 0) {
      _goToPage(currentPageIndex - 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameTemplate(
      game: _game,
      pageController: _pageController,
      currentPageIndex: _pageController.hasClients ? _pageController.page!.round() : _getPageIndexForGameState(_game.gameState),
      onPageChanged: (index) {
        setState(() {});
      },
      onNextPage: _nextPage,
      onPreviousPage: _previousPage,
      onReturnToList: () => Navigator.of(context).pop(),
      pages: [
        GameSetupScreen(
          game: _game,
          onUpdate: (updatedGame) => _updateAndSaveGame(updatedGame),
        ),
        GameRollOffsScreen(
          game: _game,
          onUpdate: (updatedGame) => _updateAndSaveGame(updatedGame),
        ),
        for (int i = 1; i <= 5; i++)
          GameRoundScreen(
            roundNumber: i,
            game: _game,
            onUpdateRound: (roundNumber, {myScore, opponentScore, priorityPlayerId, initiativePlayerId}) {
              final newGame = _game.updateRound(
                roundNumber,
                myScore: myScore,
                opponentScore: opponentScore,
                priorityPlayerId: priorityPlayerId,
                initiativePlayerId: initiativePlayerId,
              );
              _updateAndSaveGame(newGame);
            },
            onToggleQuest: (roundNumber, suiteIndex, questIndex, isMyPlayer) {
              final newGame = _game.toggleQuest(roundNumber, suiteIndex, questIndex, isMyPlayer);
              _updateAndSaveGame(newGame);
            },
          ),
        GameSummaryScreen(
          game: _game,
          onSave: () {
            final finalGame = _game.copyWith(
              gameState: GameState.completed,
              scoreOutOf20: Game.calculateScoreOutOf20(_game)
            );
            _updateAndSaveGame(finalGame);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}