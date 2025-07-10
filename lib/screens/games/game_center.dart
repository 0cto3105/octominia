// lib/screens/games/game_center.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Game? _game;
  final GameJsonStorage _gameStorage = GameJsonStorage();
  bool _gameHasBeenSavedOnce = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    if (widget.initialGame == null) {
      final prefs = await SharedPreferences.getInstance();
      final defaultPlayerName = prefs.getString('defaultPlayerName') ?? 'Me';
      _game = Game(
        date: DateTime.now(),
        myPlayerName: defaultPlayerName,
        myFactionName: '',
        myDrops: 1,
        myAuxiliaryUnits: false,
        opponentPlayerName: 'Opponent',
        opponentFactionName: '',
        opponentDrops: 1,
        opponentAuxiliaryUnits: false,
      );
    } else {
      _game = widget.initialGame!;
      _gameHasBeenSavedOnce = true;
      _game = _game!.recalculateStateFromRound(1);
    }

    int startingPageIndex = _getPageIndexForGameState(_game!.gameState);
    _pageController = PageController(initialPage: startingPageIndex);
    setState(() { _isLoading = false; });
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
    if (_game != null) {
        _saveGame();
    }
    _pageController?.dispose();
    super.dispose();
  }

  void _updateGameInMemory(Game updatedGame) {
    setState(() {
      _game = updatedGame;
    });
  }

  Future<void> _saveGame() async {
    if (_game == null) return;
    try {
      // Le recalcul final se fait maintenant avant d'aller au résumé ou de quitter
      final finalGameState = _game!.recalculateStateFromRound(1);
      
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
    _pageController?.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }
  
  // MODIFIÉ : La logique de navigation gère maintenant la finalisation du jeu
  void _nextPage() {
    if (_pageController == null || !_pageController!.hasClients) return;
    int currentPageIndex = _pageController!.page!.round();

    // Si on est sur le dernier écran (Résumé), le bouton "Suivant" devient un bouton pour quitter
    if (currentPageIndex == 7) {
      Navigator.of(context).pop();
      return;
    }

    Game gameToUpdate = _game!;

    // Si on est sur l'écran du Tour 5 (index 6) et qu'on clique sur "Suivant"
    if (currentPageIndex == 6) {
      // On finalise la partie AVANT de naviguer vers le résumé
      final finalScores = gameToUpdate.getFinalScoresOutOf20();
      final int scoreToSave = max(finalScores['myFinalScore']!, finalScores['opponentFinalScore']!);
      
      gameToUpdate = gameToUpdate.copyWith(
        gameState: GameState.completed,
        scoreOutOf20: scoreToSave,
      );
    } else {
      // Pour tous les autres clics sur "Suivant", on fait un recalcul standard
      gameToUpdate = _game!.recalculateStateFromRound(1);
    }
    
    _updateGameInMemory(gameToUpdate);
    
    if (currentPageIndex < 7) {
      _goToPage(currentPageIndex + 1);
    }
  }

  void _previousPage() {
    if (_pageController == null || !_pageController!.hasClients) return;
    int currentPageIndex = _pageController!.page!.round();
    if (currentPageIndex > 0) {
      final recalculatedGame = _game!.recalculateStateFromRound(1);
      _updateGameInMemory(recalculatedGame);
      _goToPage(currentPageIndex - 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return GameTemplate(
      game: _game!,
      pageController: _pageController!,
      currentPageIndex: _pageController!.hasClients ? _pageController!.page!.round() : _getPageIndexForGameState(_game!.gameState),
      onPageChanged: (index) {
        setState(() {});
      },
      onNextPage: _nextPage,
      onPreviousPage: _previousPage,
      onReturnToList: () => Navigator.of(context).pop(),
      pages: [
        GameSetupScreen(
          game: _game!,
          onUpdate: (updatedGame) => _updateGameInMemory(updatedGame),
        ),
        GameRollOffsScreen(
          game: _game!,
          onUpdate: (updatedGame) {
            final newGame = updatedGame.recalculateStateFromRound(1);
            _updateGameInMemory(newGame);
          }
        ),
        for (int i = 1; i <= 5; i++)
          GameRoundScreen(
            roundNumber: i,
            game: _game!,
            onUpdateRound: (roundNumber, {myScore, opponentScore, priorityPlayerId, initiativePlayerId}) {
              Game newGame;
              if (priorityPlayerId != null || initiativePlayerId != null) {
                newGame = _game!.updateRoundAndRecalculate(
                  roundNumber,
                  priorityPlayerId: priorityPlayerId,
                  initiativePlayerId: initiativePlayerId,
                );
              } else {
                newGame = _game!.setPrimaryScore(
                  roundNumber: roundNumber,
                  score: (myScore ?? opponentScore)!,
                  isMyPlayer: myScore != null,
                );
              }
              _updateGameInMemory(newGame);
            },
            onToggleQuest: (roundNumber, suiteIndex, questIndex, isMyPlayer) {
              final newGame = _game!.toggleQuest(roundNumber, suiteIndex, questIndex, isMyPlayer);
              _updateGameInMemory(newGame);
            },
          ),
        GameSummaryScreen(
          game: _game!,
          // La fonction onSave est maintenant vide car la logique est dans _nextPage
          onSave: () {}, 
        ),
      ],
    );
  }
}