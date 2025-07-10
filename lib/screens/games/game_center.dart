// lib/screens/games/game_center.dart

import 'dart:math';
import 'package:flutter/foundation.dart';
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
    _saveGame();
    _pageController.dispose();
    super.dispose();
  }

  void _updateGameInMemory(Game updatedGame) {
    setState(() {
      _game = updatedGame;
    });
  }

  Future<void> _saveGame() async {
    try {
      final finalGameState = _game.recalculateStateFromRound(1);
      
      if (!_gameHasBeenSavedOnce) {
        await _gameStorage.addGame(finalGameState);
        _gameHasBeenSavedOnce = true;
      } else {
        await _gameStorage.updateGame(finalGameState);
      }
      widget.onGameSaved(finalGameState);
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
      final recalculatedGame = _game.recalculateStateFromRound(1);
      _updateGameInMemory(recalculatedGame);
      _goToPage(currentPageIndex + 1);
    }
  }

  void _previousPage() {
    int currentPageIndex = _pageController.page!.round();
    if (currentPageIndex > 0) {
      final recalculatedGame = _game.recalculateStateFromRound(1);
      _updateGameInMemory(recalculatedGame);
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
          onUpdate: (updatedGame) => _updateGameInMemory(updatedGame),
        ),
        GameRollOffsScreen(
          game: _game,
          onUpdate: (updatedGame) {
            final newGame = updatedGame.recalculateStateFromRound(1);
            _updateGameInMemory(newGame);
          }
        ),
        for (int i = 1; i <= 5; i++)
          GameRoundScreen(
            roundNumber: i,
            game: _game,
            onUpdateRound: (roundNumber, {myScore, opponentScore, priorityPlayerId, initiativePlayerId}) {
              Game newGame;
              if (priorityPlayerId != null || initiativePlayerId != null) {
                if (kDebugMode) {
                  print("--- [Game Center] AVANT recalcul (changement de priorité/init) ---");
                  print("Jeu actuel: permanentUnderdog='${_game.permanentUnderdogPlayerId}'");
                }
                newGame = _game.updateRoundAndRecalculate(
                  roundNumber,
                  priorityPlayerId: priorityPlayerId,
                  initiativePlayerId: initiativePlayerId,
                );
                if (kDebugMode) {
                  print("--- [Game Center] APRES recalcul ---");
                  print("Nouveau jeu: permanentUnderdog='${newGame.permanentUnderdogPlayerId}'");
                  print("Nouveau Round $roundNumber: underdog='${newGame.rounds[roundNumber-1].underdogPlayerIdForRound}'");
                }
              } else {
                newGame = _game.setPrimaryScore(
                  roundNumber: roundNumber,
                  score: (myScore ?? opponentScore)!,
                  isMyPlayer: myScore != null,
                );
              }
              _updateGameInMemory(newGame);
            },
            onToggleQuest: (roundNumber, suiteIndex, questIndex, isMyPlayer) {
              final newGame = _game.toggleQuest(roundNumber, suiteIndex, questIndex, isMyPlayer);
              _updateGameInMemory(newGame);
            },
          ),
        GameSummaryScreen(
          game: _game,
          onSave: () {
            final finalScores = _game.getFinalScoresOutOf20();
            final int scoreToSave = max(finalScores['myFinalScore']!, finalScores['opponentFinalScore']!);

            final finalGame = _game.copyWith(
              gameState: GameState.completed,
              scoreOutOf20: scoreToSave,
            );
            
            _updateGameInMemory(finalGame);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}